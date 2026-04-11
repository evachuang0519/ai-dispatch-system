<!-- #include file="includes/header.asp" -->
<!-- #include file="includes/db_conn.asp" -->
<%
Dim dispatchJson, driversJson, vehiclesJson
dispatchJson = GetAPI("/api/dispatch/pending")
driversJson  = GetAPI("/api/drivers?active=true")
vehiclesJson = GetAPI("/api/vehicles?active=true")
%>
<div class="flex items-center justify-between mb-4">
  <h1 class="text-xl font-bold">人工審核調整</h1>
  <div class="flex gap-2">
    <button id="exportBtn" class="border px-4 py-2 rounded text-sm hover:bg-gray-100">匯出 Excel</button>
    <button id="confirmAllBtn" class="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700 text-sm">確認所有派單</button>
  </div>
</div>

<div id="reviewList" class="space-y-3"></div>

<script>
const dispatches = <%=dispatchJson%> || [];
const drivers    = <%=driversJson%>  || [];
const vehicles   = <%=vehiclesJson%> || [];

function confidenceBadge(v) {
  const pct = Math.round((v||0)*100);
  const cls = v>=0.8 ? 'bg-green-100 text-green-700' : v>=0.5 ? 'bg-yellow-100 text-yellow-700' : 'bg-red-100 text-red-700';
  return `<span class="px-2 py-0.5 rounded text-xs font-semibold ${cls}">${pct}%</span>`;
}

function driverOptions(selected) {
  return drivers.map(d=>`<option value="${d.id}" ${d.id==selected?'selected':''}>${d.name}</option>`).join('');
}
function vehicleOptions(selected) {
  return vehicles.map(v=>`<option value="${v.id}" ${v.id==selected?'selected':''}>${v.plate_no} (${v.vehicle_type||''})</option>`).join('');
}

const container = document.getElementById('reviewList');
if (dispatches.length === 0) {
  container.innerHTML = '<p class="text-gray-500">目前無待審核派單。請先執行 AI 派單。</p>';
} else {
  dispatches.forEach((d, idx) => {
    const card = document.createElement('div');
    card.className = 'bg-white shadow rounded p-4 border-l-4 ' + (d.confidence>=0.8 ? 'border-green-400' : d.confidence>=0.5 ? 'border-yellow-400' : 'border-red-400');
    card.id = 'card-' + d.dispatch_id;
    card.innerHTML = `
      <div class="flex items-start justify-between">
        <div>
          <span class="font-semibold">${d.order_no || '訂單 '+d.order_id}</span>
          <span class="ml-2 text-gray-500 text-sm">${d.region||''} · ${d.scheduled_time?.slice(0,16)||''}</span>
          ${confidenceBadge(d.confidence)}
        </div>
        <div class="flex gap-2">
          <button onclick="confirmOne(${d.dispatch_id})" class="bg-green-600 text-white px-3 py-1 rounded text-sm hover:bg-green-700">確認</button>
          <button onclick="toggleEdit(${d.dispatch_id})" class="border px-3 py-1 rounded text-sm hover:bg-gray-100">修改</button>
        </div>
      </div>
      <div class="mt-2 text-sm text-gray-600">
        建議：司機 <strong>${d.driver_name||d.driver_id}</strong> ／ 車輛 <strong>${d.plate_no||d.vehicle_id}</strong>
      </div>
      <div class="mt-1 text-xs text-gray-400">${d.ai_reason||''}</div>

      <div id="edit-${d.dispatch_id}" class="hidden mt-3 border-t pt-3 space-y-3">
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="block text-xs font-medium mb-1">更換司機</label>
            <select id="adj-driver-${d.dispatch_id}" class="w-full border rounded px-2 py-1 text-sm">${driverOptions(d.driver_id)}</select>
          </div>
          <div>
            <label class="block text-xs font-medium mb-1">更換車輛</label>
            <select id="adj-vehicle-${d.dispatch_id}" class="w-full border rounded px-2 py-1 text-sm">${vehicleOptions(d.vehicle_id)}</select>
          </div>
        </div>
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="block text-xs font-medium mb-1">修改原因</label>
            <select id="adj-reason-${d.dispatch_id}" class="w-full border rounded px-2 py-1 text-sm">
              <option value="driver_leave">司機休假/不可用</option>
              <option value="overload">超載，需換車</option>
              <option value="customer_request">客戶指定司機</option>
              <option value="region_mismatch">地區不符</option>
              <option value="time_conflict">時段衝突</option>
              <option value="other">其他</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-medium mb-1">補充說明</label>
            <input id="adj-note-${d.dispatch_id}" type="text" class="w-full border rounded px-2 py-1 text-sm" placeholder="選填">
          </div>
        </div>
        <button onclick="submitAdjust(${d.dispatch_id})" class="bg-blue-600 text-white px-4 py-1 rounded text-sm hover:bg-blue-700">儲存調整</button>
      </div>
    `;
    container.appendChild(card);
  });
}

function toggleEdit(id) {
  const el = document.getElementById('edit-' + id);
  el.classList.toggle('hidden');
}

async function confirmOne(dispatchId) {
  const res = await fetch(API_BASE + '/api/dispatch/confirm/' + dispatchId, {method:'POST'});
  if (res.ok) {
    document.getElementById('card-' + dispatchId).remove();
  } else alert('操作失敗');
}

async function submitAdjust(dispatchId) {
  const body = {
    dispatch_id:        dispatchId,
    adjusted_driver_id: parseInt(document.getElementById('adj-driver-'  + dispatchId).value),
    adjusted_vehicle_id:parseInt(document.getElementById('adj-vehicle-' + dispatchId).value),
    adjust_reason:      document.getElementById('adj-reason-' + dispatchId).value,
    adjust_note:        document.getElementById('adj-note-'   + dispatchId).value,
    adjusted_by:        'operator',
  };
  const res = await fetch(API_BASE + '/api/dispatch/adjust', {method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify(body)});
  if (res.ok) {
    document.getElementById('card-' + dispatchId).remove();
  } else alert('儲存失敗');
}

document.getElementById('confirmAllBtn').addEventListener('click', async () => {
  if (!confirm('確定要確認所有待審核派單？')) return;
  for (const d of dispatches) {
    await fetch(API_BASE + '/api/dispatch/confirm/' + d.dispatch_id, {method:'POST'});
  }
  location.reload();
});

document.getElementById('exportBtn').addEventListener('click', () => {
  window.location.href = '/api/dispatch/export';
});
</script>
<!-- #include file="includes/footer.asp" -->
