<!-- #include file="includes/header.asp" -->
<!-- #include file="includes/db_conn.asp" -->
<%
Dim mode, vehicleId, vehicleJson, driversJson
mode      = Request.QueryString("mode")
vehicleId = Request.QueryString("id")
vehicleJson = "null"
driversJson = GetAPI("/api/drivers?active=true")

If mode = "edit" And vehicleId <> "" Then
    vehicleJson = GetAPI("/api/vehicles/" & vehicleId)
End If
%>
<h1 class="text-xl font-bold mb-4"><%=If(mode="new","新增車輛","編輯車輛")%></h1>

<form id="vehicleForm" class="max-w-lg bg-white shadow rounded p-6 space-y-4">
  <div>
    <label class="block text-sm font-medium mb-1">車牌號碼 <span class="text-red-500">*</span></label>
    <input id="plate_no" type="text" required class="w-full border rounded px-3 py-2">
  </div>
  <div>
    <label class="block text-sm font-medium mb-1">車型</label>
    <select id="vehicle_type" class="w-full border rounded px-3 py-2">
      <option value="">請選擇</option>
      <option value="小貨車">小貨車</option>
      <option value="大貨車">大貨車</option>
      <option value="冷凍車">冷凍車</option>
    </select>
  </div>
  <div>
    <label class="block text-sm font-medium mb-1">最大載重 (kg)</label>
    <input id="max_weight" type="number" min="0" class="w-full border rounded px-3 py-2">
  </div>
  <div>
    <label class="block text-sm font-medium mb-1">指派司機</label>
    <select id="driver_id" class="w-full border rounded px-3 py-2">
      <option value="">未指派</option>
    </select>
  </div>
  <div>
    <label class="block text-sm font-medium mb-1">備註</label>
    <textarea id="note" rows="2" class="w-full border rounded px-3 py-2"></textarea>
  </div>
  <div class="flex gap-3">
    <button type="submit" class="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700">儲存</button>
    <a href="vehicles.asp" class="px-6 py-2 rounded border hover:bg-gray-100">取消</a>
  </div>
</form>

<script>
const mode = "<%=mode%>";
const vehicleId = "<%=vehicleId%>";
const vehicle = <%=vehicleJson%>;
const drivers = <%=driversJson%> || [];

// 填入司機下拉
const driverSel = document.getElementById('driver_id');
drivers.forEach(d => {
  const opt = new Option(d.name, d.id);
  driverSel.appendChild(opt);
});

if (vehicle) {
  document.getElementById('plate_no').value = vehicle.plate_no || '';
  document.getElementById('vehicle_type').value = vehicle.vehicle_type || '';
  document.getElementById('max_weight').value = vehicle.max_weight || '';
  document.getElementById('driver_id').value = vehicle.driver_id || '';
  document.getElementById('note').value = vehicle.note || '';
}

document.getElementById('vehicleForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const body = {
    plate_no:     document.getElementById('plate_no').value,
    vehicle_type: document.getElementById('vehicle_type').value,
    max_weight:   document.getElementById('max_weight').value || null,
    driver_id:    document.getElementById('driver_id').value || null,
    note:         document.getElementById('note').value,
  };
  const url    = mode === 'new' ? '/api/vehicles' : '/api/vehicles/' + vehicleId;
  const method = mode === 'new' ? 'POST' : 'PUT';
  const res = await fetch(url, {method, headers:{'Content-Type':'application/json'}, body: JSON.stringify(body)});
  if (res.ok) location.href = 'vehicles.asp';
  else alert('儲存失敗，請確認資料後重試');
});
</script>
<!-- #include file="includes/footer.asp" -->
