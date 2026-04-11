<!-- #include file="includes/header.asp" -->
<!-- #include file="includes/db_conn.asp" -->
<%
' 單筆派單調整（從 dispatch_review 連結過來）
Dim dispatchId, dispatchJson, driversJson, vehiclesJson
dispatchId   = Request.QueryString("id")
dispatchJson = GetAPI("/api/dispatch/" & dispatchId)
driversJson  = GetAPI("/api/drivers?active=true")
vehiclesJson = GetAPI("/api/vehicles?active=true")
%>
<h1 class="text-xl font-bold mb-4">修改派單</h1>

<form id="editForm" class="max-w-lg bg-white shadow rounded p-6 space-y-4">
  <div>
    <label class="block text-sm font-medium mb-1">更換司機</label>
    <select id="driver_id" class="w-full border rounded px-3 py-2"></select>
  </div>
  <div>
    <label class="block text-sm font-medium mb-1">更換車輛</label>
    <select id="vehicle_id" class="w-full border rounded px-3 py-2"></select>
  </div>
  <div>
    <label class="block text-sm font-medium mb-1">修改原因</label>
    <select id="adjust_reason" class="w-full border rounded px-3 py-2">
      <option value="driver_leave">司機休假/不可用</option>
      <option value="overload">超載，需換車</option>
      <option value="customer_request">客戶指定司機</option>
      <option value="region_mismatch">地區不符</option>
      <option value="time_conflict">時段衝突</option>
      <option value="other">其他</option>
    </select>
  </div>
  <div>
    <label class="block text-sm font-medium mb-1">補充說明</label>
    <textarea id="adjust_note" rows="2" class="w-full border rounded px-3 py-2"></textarea>
  </div>
  <div class="flex gap-3">
    <button type="submit" class="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700">儲存</button>
    <a href="dispatch_review.asp" class="px-6 py-2 rounded border hover:bg-gray-100">取消</a>
  </div>
</form>

<script>
const dispatch = <%=dispatchJson%> || {};
const drivers  = <%=driversJson%>  || [];
const vehicles = <%=vehiclesJson%> || [];

const driverSel  = document.getElementById('driver_id');
const vehicleSel = document.getElementById('vehicle_id');
drivers.forEach(d  => driverSel.appendChild(new Option(d.name, d.id)));
vehicles.forEach(v => vehicleSel.appendChild(new Option(v.plate_no + ' (' + (v.vehicle_type||'') + ')', v.id)));

driverSel.value  = dispatch.driver_id  || '';
vehicleSel.value = dispatch.vehicle_id || '';

document.getElementById('editForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const body = {
    dispatch_id:         parseInt("<%=dispatchId%>"),
    adjusted_driver_id:  parseInt(driverSel.value),
    adjusted_vehicle_id: parseInt(vehicleSel.value),
    adjust_reason:       document.getElementById('adjust_reason').value,
    adjust_note:         document.getElementById('adjust_note').value,
    adjusted_by:         'operator',
  };
  const res = await fetch(API_BASE + '/api/dispatch/adjust', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify(body)
  });
  if (res.ok) location.href = 'dispatch_review.asp';
  else alert('儲存失敗');
});
</script>
<!-- #include file="includes/footer.asp" -->
