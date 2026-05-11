// ========================================================
//  OPT-Training — Google Apps Script Backend
//  วิธีติดตั้ง:
//  1. เปิด Google Sheets ใหม่ → Extensions → Apps Script
//  2. วางโค้ดนี้ทั้งหมด → Save
//  3. Deploy → New deployment → Web app
//     - Execute as: Me
//     - Who has access: Anyone
//  4. Copy URL ที่ได้ → วางใน index.html บรรทัด GS_URL
// ========================================================

function doGet(e) {
  const action = (e.parameter && e.parameter.action) || 'load';
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  if (action === 'load') {
    const result = {
      employees:     readSheet(ss, 'employees'),
      trainings:     readSheet(ss, 'trainings'),
      quizResults:   readSheet(ss, 'quizResults'),
      customQuiz:    readSheet(ss, 'customQuiz'),
      courseHistory: readSheet(ss, 'courseHistory'),
      quizMeta:      readSheetSingleton(ss, 'quizMeta')
    };
    return respond(result);
  }

  return respond({ error: 'Unknown action' });
}

function doPost(e) {
  const data = JSON.parse(e.postData.contents);
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  if (data.action === 'save') {
    saveRow(ss, data.collection, data.id, data.record);
  } else if (data.action === 'delete') {
    deleteRow(ss, data.collection, data.id);
  } else if (data.action === 'save_many') {
    (data.records || []).forEach(r => saveRow(ss, data.collection, r.id, r));
  }

  return respond({ status: 'ok' });
}

function respond(data) {
  return ContentService
    .createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}

function readSheet(ss, name) {
  const sheet = ss.getSheetByName(name);
  if (!sheet) return [];
  const vals = sheet.getDataRange().getValues();
  if (vals.length < 2) return [];
  const headers = vals[0];
  return vals.slice(1).map(row => {
    const obj = {};
    headers.forEach((h, i) => {
      if (!h) return;
      const v = row[i];
      if (typeof v === 'string' && (v.startsWith('{') || v.startsWith('['))) {
        try { obj[h] = JSON.parse(v); } catch(_) { obj[h] = v; }
      } else {
        obj[h] = (v === '' || v === null) ? null : v;
      }
    });
    return obj;
  });
}

// Singleton-style sheet (e.g. quizMeta) — returns the first/only row's record or {}
function readSheetSingleton(ss, name) {
  const rows = readSheet(ss, name);
  return rows.length ? rows[0] : {};
}

function saveRow(ss, name, id, record) {
  let sheet = ss.getSheetByName(name);
  if (!sheet) {
    sheet = ss.insertSheet(name);
    sheet.appendRow(Object.keys(record));
  }

  const allVals = sheet.getDataRange().getValues();
  let headers = allVals[0];

  // Add missing headers
  const newKeys = Object.keys(record).filter(k => !headers.includes(k));
  if (newKeys.length > 0) {
    headers = headers.concat(newKeys);
    sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
  }

  const idIdx = headers.indexOf('id');
  let rowIdx = -1;
  for (let i = 1; i < allVals.length; i++) {
    if (String(allVals[i][idIdx]) === String(id)) { rowIdx = i + 1; break; }
  }

  const row = headers.map(h => {
    const v = record[h];
    if (v === null || v === undefined) return '';
    if (typeof v === 'object') return JSON.stringify(v);
    return v;
  });

  if (rowIdx > 0) {
    sheet.getRange(rowIdx, 1, 1, row.length).setValues([row]);
  } else {
    sheet.appendRow(row);
  }
}

function deleteRow(ss, name, id) {
  const sheet = ss.getSheetByName(name);
  if (!sheet) return;
  const vals = sheet.getDataRange().getValues();
  const idIdx = vals[0].indexOf('id');
  for (let i = vals.length - 1; i >= 1; i--) {
    if (String(vals[i][idIdx]) === String(id)) {
      sheet.deleteRow(i + 1);
      return;
    }
  }
}
