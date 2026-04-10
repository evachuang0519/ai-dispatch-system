<!-- #include file="includes/header.asp" -->
<!-- #include file="includes/db_conn.asp" -->
<%
Dim mode, driverId, driverJson
mode     = Request.QueryString("mode")
driverId = Request.QueryString("id")
driverJson = "null"

If mode = "edit" And driverId <> "" Then
    driverJson = GetAPI("/api/drivers/" & driverId)
End If
%>
<h1 class="text-xl font-bold mb-4"><%=If(mode="new","新增司機","編輯司機")%></h1>

<form id="driverForm" class="max-w-lg bg-white shadow rounded p-6 space-y-4">
  <div>
    <label class="block text-sm font-medium mb-1">姓名 <span class="text-red-500">*</span></label>
    <input id="name" type="text" required class="w-full border rounded px-3 py-2">
  </div>
  <div>
    <label class="block text-sm font-medium mb-1">電話</label>
    <input id="phone" type="text" class="w-full border rounded px-3 py-2">
  </div>
  <div>
    <label class="block text-sm font-medium mb-1">可操作車型</label>
    <select id="vehicle_type" class="w-full border rounded px-3 py-2">
      <option value="">請選擇</option>
      <option value="小貨車">小貨車</option>
      <option value="大貨車">大貨車</option>
      <option value="冷凍車">冷凍車</option>
      <option value="小貨車,大貨車">小貨車,大貨車</option>
    </select>
  </div>
  <div>
    <label class="block text-sm font-medium mb-1">負責地區</label>
    <select id="region" class="w-full border rounded px-3 py-2">
      <option value="">請選擇</option>
      <option value="北區">北區</option>
      <option value="中區">中區</option>
      <option value="南區">南區</option>
    </select>
  </div>
  <div>
    <label class="block text-sm font-medium mb-1">備註</label>
    <textarea id="note" rows="2" class="w-full border rounded px-3 py-2"></textarea>
  </div>
  <div class="flex gap-3">
    <button type="submit" class="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700">儲存</button>
    <a href="drivers.asp" class="px-6 py-2 rounded border hover:bg-gray-100">取消</a>
  </div>
</form>

<script>
const mode = "<%=mode%>";
const driverId = "<%=driverId%>";
const driver = <%=driverJson%>;

if (driver) {
  document.getElementById('name').value = driver.name || '';
  document.getElementById('phone').value = driver.phone || '';
  document.getElementById('vehicle_type').value = driver.vehicle_type || '';
  document.getElementById('region').value = driver.region || '';
  document.getElementById('note').value = driver.note || '';
}

document.getElementById('driverForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const body = {
    name: document.getElementById('name').value,
    phone: document.getElementById('phone').value,
    vehicle_type: document.getElementById('vehicle_type').value,
    region: document.getElementById('region').value,
    note: document.getElementById('note').value,
  };
  const url = mode === 'new' ? '/api/drivers' : '/api/drivers/' + driverId;
  const method = mode === 'new' ? 'POST' : 'PUT';
  const res = await fetch(url, {method, headers:{'Content-Type':'application/json'}, body: JSON.stringify(body)});
  if (res.ok) {
    location.href = 'drivers.asp';
  } else {
    alert('儲存失敗，請確認資料後重試');
  }
});
</script>
<!-- #include file="includes/footer.asp" -->
