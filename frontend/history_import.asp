<!-- #include file="includes/header.asp" -->
<h1 class="text-xl font-bold mb-4">歷史派單批次匯入</h1>

<div class="mb-4">
  <a href="/api/history/template" class="text-blue-600 hover:underline text-sm">⬇ 下載 Excel 範本</a>
</div>

<div class="bg-white shadow rounded p-6 max-w-xl space-y-4">
  <div>
    <label class="block text-sm font-medium mb-2">選擇 Excel 檔案</label>
    <input id="fileInput" type="file" accept=".xlsx,.xls" class="block w-full text-sm border rounded px-3 py-2">
  </div>
  <button id="uploadBtn" class="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700">上傳並預覽</button>
</div>

<div id="previewSection" class="mt-6 hidden">
  <h2 class="font-semibold mb-2">預覽清單 <span id="previewCount" class="text-gray-500 text-sm"></span></h2>
  <div id="errorList" class="mb-3 text-sm text-red-600 hidden"></div>
  <div class="overflow-x-auto">
    <table id="previewTable" class="w-full text-sm border-collapse bg-white shadow rounded overflow-hidden"></table>
  </div>
  <div class="mt-4 flex gap-3">
    <button id="confirmBtn" class="bg-green-600 text-white px-6 py-2 rounded hover:bg-green-700">確認匯入</button>
    <a href="history_manage.asp" class="px-6 py-2 rounded border hover:bg-gray-100">取消</a>
  </div>
</div>

<div id="resultSection" class="mt-6 hidden bg-green-50 border border-green-200 rounded p-4 text-sm"></div>

<script>
let previewData = [];

document.getElementById('uploadBtn').addEventListener('click', async () => {
  const file = document.getElementById('fileInput').files[0];
  if (!file) { alert('請選擇 Excel 檔案'); return; }
  const formData = new FormData();
  formData.append('file', file);
  const res = await fetch('/api/history/import', {method:'POST', body: formData});
  const json = await res.json();
  previewData = json.preview || [];

  document.getElementById('previewCount').textContent = `共 ${previewData.length} 筆`;
  document.getElementById('previewSection').classList.remove('hidden');

  // 錯誤提示
  if (json.errors && json.errors.length > 0) {
    const errDiv = document.getElementById('errorList');
    errDiv.textContent = '解析警告：' + json.errors.map(e => `第${e.row}列 ${e.field} (${e.error})`).join('、');
    errDiv.classList.remove('hidden');
  }

  // 預覽表格
  if (previewData.length > 0) {
    const keys = ['order_no','customer_name','region','scheduled_time','weight','driver_name','plate_no'];
    const labels = ['訂單編號','客戶名稱','地區','預定時段','重量','派單司機','車牌'];
    let html = '<thead class="bg-blue-50"><tr>' + labels.map(l=>`<th class="px-3 py-2 border-b text-left">${l}</th>`).join('') + '</tr></thead><tbody>';
    previewData.forEach(r => {
      html += '<tr>' + keys.map(k=>`<td class="px-3 py-2 border-b">${r[k]||''}</td>`).join('') + '</tr>';
    });
    html += '</tbody>';
    document.getElementById('previewTable').innerHTML = html;
  }
});

document.getElementById('confirmBtn').addEventListener('click', async () => {
  const res = await fetch('/api/history/import/confirm', {
    method: 'POST',
    headers: {'Content-Type':'application/json'},
    body: JSON.stringify(previewData)
  });
  const json = await res.json();
  const resultDiv = document.getElementById('resultSection');
  resultDiv.classList.remove('hidden');
  resultDiv.innerHTML = `匯入完成：成功 <strong>${json.inserted}</strong> 筆` +
    (json.errors?.length ? `，失敗 <strong class="text-red-600">${json.errors.length}</strong> 筆` : '');
  document.getElementById('previewSection').classList.add('hidden');
});
</script>
<!-- #include file="includes/footer.asp" -->
