<!-- #include file="includes/header.asp" -->
<!-- #include file="includes/db_conn.asp" -->
<%
Dim regionFilter, dateFrom, dateTo, apiUrl
regionFilter = Request.QueryString("region")
dateFrom     = Request.QueryString("date_from")
dateTo       = Request.QueryString("date_to")

apiUrl = "/api/history?"
If regionFilter <> "" Then apiUrl = apiUrl & "region=" & Server.URLEncode(regionFilter) & "&"
If dateFrom     <> "" Then apiUrl = apiUrl & "date_from=" & dateFrom & "&"
If dateTo       <> "" Then apiUrl = apiUrl & "date_to=" & dateTo & "&"

Dim jsonData
jsonData = GetAPI(apiUrl)
%>
<div class="flex items-center justify-between mb-4">
  <h1 class="text-xl font-bold">歷史派單維護</h1>
  <div class="flex gap-2">
    <a href="history_import.asp" class="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700">批次匯入</a>
    <a href="history_edit.asp?mode=new" class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">＋ 單筆新增</a>
  </div>
</div>

<form method="get" class="flex gap-3 mb-4 flex-wrap">
  <input name="date_from" type="date" value="<%=dateFrom%>" class="border rounded px-3 py-1 text-sm">
  <span class="self-center text-gray-400">～</span>
  <input name="date_to"   type="date" value="<%=dateTo%>"   class="border rounded px-3 py-1 text-sm">
  <select name="region" class="border rounded px-3 py-1 text-sm">
    <option value="">所有地區</option>
    <option value="北區" <%If regionFilter="北區" Then Response.Write "selected"%>>北區</option>
    <option value="中區" <%If regionFilter="中區" Then Response.Write "selected"%>>中區</option>
    <option value="南區" <%If regionFilter="南區" Then Response.Write "selected"%>>南區</option>
  </select>
  <button type="submit" class="bg-gray-200 px-4 py-1 rounded text-sm hover:bg-gray-300">篩選</button>
</form>

<div id="tableContainer"><p class="text-sm text-gray-500">載入中...</p></div>

<script>
const data = <%=jsonData%>;
const rows = Array.isArray(data) ? data : [];
const container = document.getElementById('tableContainer');
if (rows.length === 0) {
  container.innerHTML = '<p class="text-gray-500">無資料</p>';
} else {
  let html = `<table class="w-full text-sm border-collapse bg-white shadow rounded overflow-hidden">
    <thead class="bg-blue-50 text-left">
      <tr>
        <th class="px-3 py-2 border-b">訂單編號</th>
        <th class="px-3 py-2 border-b">客戶</th>
        <th class="px-3 py-2 border-b">地區</th>
        <th class="px-3 py-2 border-b">預定時段</th>
        <th class="px-3 py-2 border-b">司機</th>
        <th class="px-3 py-2 border-b">車牌</th>
        <th class="px-3 py-2 border-b">派單方式</th>
        <th class="px-3 py-2 border-b">操作</th>
      </tr>
    </thead><tbody>`;
  rows.forEach(r => {
    html += `<tr class="hover:bg-gray-50">
      <td class="px-3 py-2 border-b">${r.order_no||''}</td>
      <td class="px-3 py-2 border-b">${r.customer_name||''}</td>
      <td class="px-3 py-2 border-b">${r.region||''}</td>
      <td class="px-3 py-2 border-b">${r.scheduled_time ? r.scheduled_time.replace('T',' ').slice(0,16) : ''}</td>
      <td class="px-3 py-2 border-b">${r.driver_name||''}</td>
      <td class="px-3 py-2 border-b">${r.plate_no||''}</td>
      <td class="px-3 py-2 border-b">${r.assigned_by||''}</td>
      <td class="px-3 py-2 border-b flex gap-2">
        <a href="history_edit.asp?mode=edit&id=${r.id}" class="text-blue-600 hover:underline">編輯</a>
        <button onclick="deleteHistory(${r.id})" class="text-red-500 hover:underline">刪除</button>
      </td>
    </tr>`;
  });
  html += '</tbody></table>';
  container.innerHTML = html;
}

async function deleteHistory(id) {
  if (!confirm('確定要刪除此筆記錄？此操作無法還原。')) return;
  const res = await fetch('/api/history/' + id, {method:'DELETE'});
  if (res.ok) location.reload();
  else alert('刪除失敗');
}
</script>
<!-- #include file="includes/footer.asp" -->
