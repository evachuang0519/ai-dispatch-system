<!-- #include file="includes/header.asp" -->
<h1 class="text-xl font-bold mb-4">上傳未派車訂單</h1>

<div class="mb-4">
  <a href="/api/upload/template" class="text-blue-600 hover:underline text-sm">⬇ 下載 Excel 範本</a>
</div>

<div class="bg-white shadow rounded p-6 max-w-xl space-y-4">
  <div>
    <label class="block text-sm font-medium mb-2">選擇 Excel 檔案</label>
    <input id="fileInput" type="file" accept=".xlsx,.xls" class="block w-full text-sm border rounded px-3 py-2">
  </div>
  <button id="uploadBtn" class="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700">上傳並預覽</button>
</div>

<div id="previewSection" class="mt-6 hidden">
  <h2 class="font-semibold mb-2">
    解析結果：<span id="previewCount" class="text-gray-500 text-sm"></span>
  </h2>
  <div id="errorList" class="mb-3 text-sm text-red-600 hidden"></div>
  <div class="overflow-x-auto">
    <table id="previewTable" class="w-full text-sm border-collapse bg-white shadow rounded overflow-hidden"></table>
  </div>
  <div class="mt-4 flex gap-3">
    <button id="confirmBtn" class="bg-green-600 text-white px-6 py-2 rounded hover:bg-green-700">確認匯入</button>
    <a href="index.asp" class="px-6 py-2 rounded border hover:bg-gray-100">取消</a>
  </div>
</div>

<div id="resultSection" class="mt-6 hidden"></div>

<script>
document.getElementById('uploadBtn').addEventListener('click', async () => {
  const file = document.getElementById('fileInput').files[0];
  if (!file) { alert('請選擇 Excel 檔案'); return; }

  const btn = document.getElementById('uploadBtn');
  btn.textContent = '上傳中...';
  btn.disabled = true;

  const formData = new FormData();
  formData.append('file', file);
  const res = await fetch(API_BASE + '/api/upload', {method:'POST', body: formData});
  const json = await res.json();

  btn.textContent = '上傳並預覽';
  btn.disabled = false;

  const preview = json.preview || [];
  document.getElementById('previewCount').textContent = `共 ${preview.length} 筆`;
  document.getElementById('previewSection').classList.remove('hidden');

  if (json.errors?.length > 0) {
    const errDiv = document.getElementById('errorList');
    errDiv.textContent = '解析警告：' + json.errors.map(e=>`第${e.row}列 ${e.field}`).join('、');
    errDiv.classList.remove('hidden');
  }

  if (preview.length > 0) {
    const keys   = ['order_date','customer_name','trip_type','pickup_time','region','departure','destination','driver_name','plate_no'];
    const labels = ['日期','個案名','性質','客上','地區','出發地','目的地','司機','車號'];
    let html = '<thead class="bg-blue-50"><tr>' +
      labels.map(l=>`<th class="px-3 py-2 border-b text-left">${l}</th>`).join('') +
      '</tr></thead><tbody>';
    preview.forEach(r => {
      html += '<tr>' + keys.map(k=>`<td class="px-3 py-2 border-b">${r[k]??''}</td>`).join('') + '</tr>';
    });
    html += '</tbody>';
    document.getElementById('previewTable').innerHTML = html;
  }
});

document.getElementById('confirmBtn').addEventListener('click', async () => {
  const btn = document.getElementById('confirmBtn');
  btn.textContent = '匯入中...';
  btn.disabled = true;

  const res = await fetch(API_BASE + '/api/upload/confirm', {method:'POST', headers:{'Content-Type':'application/json'}, body:'null'});
  const json = await res.json();

  const resultDiv = document.getElementById('resultSection');
  resultDiv.classList.remove('hidden');
  resultDiv.className = 'mt-6 p-4 rounded text-sm ' + (json.errors?.length ? 'bg-yellow-50 border border-yellow-200' : 'bg-green-50 border border-green-200');
  resultDiv.innerHTML = `匯入完成：成功 <strong>${json.inserted}</strong> 筆` +
    (json.errors?.length ? `，失敗 <strong class="text-red-600">${json.errors.length}</strong> 筆` : '') +
    `　<a href="dispatch.asp" class="ml-4 text-blue-600 hover:underline font-medium">立即派單 →</a>`;
  document.getElementById('previewSection').classList.add('hidden');
});
</script>
<!-- #include file="includes/footer.asp" -->
