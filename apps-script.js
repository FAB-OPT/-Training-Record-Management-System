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

  // AI proxy — keep API key server-side (Script Properties → ANTHROPIC_API_KEY)
  if (data.action === 'ai_quiz') {
    return respond(generateAiQuiz(data));
  }

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

// ========================================================
//  AI Quiz Generator (Anthropic Claude API proxy)
//  Setup: Project Settings → Script Properties →
//         add property "ANTHROPIC_API_KEY" = sk-ant-...
//         (สมัคร + เติม $5 ที่ https://console.anthropic.com)
// ========================================================
// Run this once to trigger Google OAuth permission for external requests.
// MUST NOT be wrapped in try/catch — the unhandled exception is what
// makes Google show the authorization popup.
function authorizeExternalRequests() {
  const resp = UrlFetchApp.fetch('https://www.google.com');
  Logger.log('OK ' + resp.getResponseCode());
}

function generateAiQuiz(req) {
  try {
    const apiKey = PropertiesService.getScriptProperties().getProperty('ANTHROPIC_API_KEY');
    if (!apiKey) return { error: 'ยังไม่ได้ตั้ง ANTHROPIC_API_KEY ใน Script Properties' };

    const moduleName = req.moduleName || '';
    const group = req.group || '';
    const subtopics = req.subtopics || [];
    const perSub = req.perSub || null; // [{subtopic, n}, ...] when admin set per-subtopic counts
    const n = req.n || 5;
    const focus = req.focus || '';
    const existingQuestions = req.existingQuestions || []; // [{q, opts:{A,B,C,D}, ans}, ...]

    var subtopicSpec;
    if (perSub && perSub.length) {
      subtopicSpec = perSub.map(function(p){ return '- "' + p.subtopic + '" → ' + p.n + ' ข้อ'; }).join('\n');
    } else {
      subtopicSpec = subtopics.map(function(s){ return '- ' + s; }).join('\n');
    }

    // Build list of existing questions to avoid duplicating
    var existingSpec = '';
    if (existingQuestions.length) {
      existingSpec = '\n\nคำถามที่มีอยู่แล้ว (อย่าสร้างคำถามที่มีเนื้อหาหรือความหมายซ้ำหรือคล้ายกับด้านล่างนี้ ห้ามถามเรื่องเดิม):\n' +
        existingQuestions.slice(0, 60).map(function(q, i){ return (i+1) + '. ' + (q.q || '').replace(/\n/g, ' '); }).join('\n');
    }

    const prompt = 'คุณเป็นผู้สร้างข้อสอบสำหรับ Santa Fe Steak (ร้านอาหาร) — สร้างข้อสอบ ' + n + ' ข้อ สำหรับ Module: "' + moduleName + '" (กลุ่ม: ' + group + ')\n\n' +
      (perSub && perSub.length ? 'จำนวนข้อสอบต่อหัวข้อย่อย (ต้องตรงเป๊ะ):\n' : 'หัวข้อย่อยที่ต้องครอบคลุม:\n') +
      subtopicSpec +
      (focus ? ('\n\nโฟกัสเพิ่มเติม: ' + focus) : '') +
      existingSpec +
      '\n\nข้อกำหนด:\n' +
      '- คำถามภาษาไทย ชัดเจน เกี่ยวกับการปฏิบัติงานจริงในร้านอาหาร\n' +
      '- 4 ตัวเลือก A B C D ความยาวใกล้เคียงกัน\n' +
      '- คำตอบที่ถูกต้องกระจาย A/B/C/D อย่างสมดุล\n' +
      '- หลีกเลี่ยงตัวเลือก "ถูกทุกข้อ" หรือ "ไม่มีข้อใดถูก"\n' +
      '- คำถามแต่ละครั้งควรหลากหลาย ไม่ซ้ำซาก\n' +
      (existingQuestions.length ? '- **สำคัญมาก:** ห้ามสร้างคำถามที่เนื้อหาหรือความหมายซ้ำกับรายการที่ระบุไว้ข้างบน แม้จะใช้คำต่างกันก็ห้าม\n' : '') +
      (perSub && perSub.length ? '- เรียงคำถามตามลำดับหัวข้อย่อยตามที่ระบุข้างบน\n' : '') +
      '\nตอบกลับเป็น JSON array เท่านั้น (ไม่มี markdown, ไม่มี text อื่น) ตามรูปแบบนี้:\n' +
      '[{"q":"คำถาม...","opts":{"A":"...","B":"...","C":"...","D":"..."},"ans":"A"}, ...]';

    const payload = JSON.stringify({
      model: 'claude-sonnet-4-5',
      max_tokens: 4096,
      messages: [{ role: 'user', content: prompt }],
    });

    // Retry up to 3 times on 429/529 with exponential backoff
    var resp, code, body;
    for (var attempt = 0; attempt < 3; attempt++) {
      resp = UrlFetchApp.fetch('https://api.anthropic.com/v1/messages', {
        method: 'post',
        contentType: 'application/json',
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        payload: payload,
        muteHttpExceptions: true,
      });
      code = resp.getResponseCode();
      body = resp.getContentText();
      if (code !== 429 && code !== 529) break;
      Utilities.sleep(2000 * (attempt + 1)); // 2s, 4s, 6s
    }
    if (code !== 200) return { error: 'Claude API ' + code + ': ' + body.slice(0, 300) };

    const data = JSON.parse(body);
    const text = (data.content && data.content[0] && data.content[0].text) || '';
    if (!text) return { error: 'Claude ไม่ได้ตอบกลับ' };

    const m = text.match(/\[[\s\S]*\]/);
    if (!m) return { error: 'AI ไม่ได้ตอบเป็น JSON' };

    const arr = JSON.parse(m[0]);
    const valid = arr.filter(function(q){
      return q && q.q && q.opts && q.opts.A && q.opts.B && q.opts.C && q.opts.D
        && ['A','B','C','D'].indexOf(q.ans) >= 0;
    });
    return { questions: valid };
  } catch (err) {
    return { error: 'Server error: ' + err.message };
  }
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

