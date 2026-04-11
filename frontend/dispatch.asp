<%@ CodePage=65001 %>
<!-- #include file="includes/header.asp" -->
<!-- #include file="includes/db_conn.asp" -->
<%
Dim pendingJson
pendingJson = GetAPI("/api/orders?status=pending")
%>
<div class="flex items-center justify-between mb-4">
  <h1 class="text-xl font-bold">AI 自動派單</h1>
  <button id="dispatchBtn" class="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700">執行 AI 派單</button>
</div>

<h2 class="text-sm font-medium text-gray-500 mb-3">待派訂單</h2>
<div id="pendingTable">
<%
If pendingJson = "" Or pendingJson = "[]" Then
    Response.Write "<p class=""text-gray-500 text-sm"">目前無待派訂單。請先至「上傳訂單」匯入資料。</p>"
Else
    Response.Write "<div class=""text-sm text-gray-600 mb-2"">資料載入中...</div>"
End If
%>
</div>

<div id="loadingMsg" class="hidden mt-4 text-blue-600 text-sm animate-pulse">AI 派單分析中，請稍候...</div>

<div id="resultSection" class="mt-6 hidden">
  <div class="flex items-center justify-between mb-3">
    <h2 class="font-semibold">AI 派單建議</h2>
    <a href="dispatch_review.asp" class="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700 text-sm">前往審核 →</a>
  </div>
  <div class="overflow-x-auto">
    <table id="suggestionTable" class="w-full text-sm border-collapse bg-white shadow rounded overflow-hidden">
      <thead class="bg-blue-50 text-left">
        <tr>
          <th class="px-3 py-2 border-b">個案名</th>
          <th class="px-3 py-2 border-b">建議司機</th>
          <th class="px-3 py-2 border-b">建議車輛</th>
          <th class="px-3 py-2 border-b">信心分數</th>
          <th class="px-3 py-2 border-b">AI 說明</th>
        </tr>
      </thead>
      <tbody id="suggestionBody"></tbody>
    </table>
  </div>
</div>

<script>
const pending = <%=pendingJson%> || [];
const pendingDiv = document.getElementById('pendingTable');

if (pending.length > 0) {
  let html = `<table class="w-full text-sm border-collapse bg-white shadow rounded overflow-hidden">
    <thead class="bg-gray-50 text-left">
      <tr>
        <th class="px-3 py-2 border-b">日期</th>
        <th class="px-3 py-2 border-b">個案名</th>
        <th class="px-3 py-2 border-b">性質</th>
        <th class="px-3 py-2 border-b">客上</th>
        <th class="px-3 py-2 border-b">地區</th>
        <th class="px-3 py-2 border-b">出發地</th>
        <th class="px-3 py-2 border-b">目的地</th>
      </tr>
    </thead><tbody>`;
  pending.forEach(o => {
    const d = o.order_date ? o.order_date.slice(0,10) : '';
    const t = o.pickup_time ? o.pickup_time.slice(0,5) : '';
    html += `<tr class="hover:bg-gray-50">
      <td class="px-3 py-2 border-b">${d}</td>
      <td class="px-3 py-2 border-b">${o.customer_name||''}</td>
      <td class="px-3 py-2 border-b">${o.trip_type||''}</td>
      <td class="px-3 py-2 border-b">${t}</td>
      <td class="px-3 py-2 border-b">${o.region||''}</td>
      <td class="px-3 py-2 border-b">${o.departure||''}</td>
      <td class="px-3 py-2 border-b">${o.destination||''}</td>
    </tr>`;
  });
  html += '</tbody></table>';
  pendingDiv.innerHTML = html;
}

function confidenceClass(v) {
  if (v >= 0.8) return 'text-green-600 font-semibold';
  if (v >= 0.5) return 'text-yellow-600 font-semibold';
  return 'text-red-600 font-semibold';
}

document.getElementById('dispatchBtn').addEventListener('click', async () => {
  const btn = document.getElementById('dispatchBtn');
  btn.disabled = true;
  btn.textContent = '分析中...';
  document.getElementById('loadingMsg').classList.remove('hidden');

  try {
    const res = await fetch(API_BASE + '/api/dispatch', {method:'POST'});
    const json = await res.json();
    document.getElementById('loadingMsg').classList.add('hidden');

    if (!res.ok) { alert('派單失敗：' + (json.detail || res.status)); return; }

    const suggestions = json.suggestions || [];
    const tbody = document.getElementById('suggestionBody');
    tbody.innerHTML = suggestions.map(s => `
      <tr>
        <td class="px-3 py-2 border-b">${s.order_id}</td>
        <td class="px-3 py-2 border-b">${s.driver_id}</td>
        <td class="px-3 py-2 border-b">${s.vehicle_id}</td>
        <td class="px-3 py-2 border-b"><span class="${confidenceClass(s.confidence)}">${(s.confidence*100).toFixed(0)}%</span></td>
        <td class="px-3 py-2 border-b text-gray-600">${s.reason||''}</td>
      </tr>`).join('');
    document.getElementById('resultSection').classList.remove('hidden');
  } catch(e) {
    alert('系統錯誤：' + e.message);
  } finally {
    btn.disabled = false;
    btn.textContent = '重新派單';
  }
});
</script>
<!-- #include file="includes/footer.asp" -->
