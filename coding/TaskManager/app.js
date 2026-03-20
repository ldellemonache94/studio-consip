// ── State ──────────────────────────────────────────────
let tasks = JSON.parse(localStorage.getItem('tasks')) || [];
let currentFilter = 'all';

// ── DOM refs ───────────────────────────────────────────
const taskInput      = document.getElementById('taskInput');
const prioritySelect = document.getElementById('prioritySelect');
const addBtn         = document.getElementById('addBtn');
const taskList       = document.getElementById('taskList');
const taskCount      = document.getElementById('taskCount');
const clearCompleted = document.getElementById('clearCompleted');
const filterBtns     = document.querySelectorAll('.filter-btn');

// ── Helpers ────────────────────────────────────────────
const save = () => localStorage.setItem('tasks', JSON.stringify(tasks));

const formatDate = (iso) => {
  const d = new Date(iso);
  return d.toLocaleDateString('it-IT', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' });
};

// ── Core actions ───────────────────────────────────────
function addTask() {
  const text = taskInput.value.trim();
  if (!text) return taskInput.focus();

  tasks.unshift({
    id:        Date.now(),
    text,
    priority:  prioritySelect.value,
    completed: false,
    createdAt: new Date().toISOString()
  });

  taskInput.value = '';
  save();
  render();
}

function toggleTask(id) {
  const t = tasks.find(t => t.id === id);
  if (t) { t.completed = !t.completed; save(); render(); }
}

function deleteTask(id) {
  tasks = tasks.filter(t => t.id !== id);
  save();
  render();
}

function clearDone() {
  tasks = tasks.filter(t => !t.completed);
  save();
  render();
}

// ── Render ─────────────────────────────────────────────
function render() {
  const filtered = tasks.filter(t => {
    if (currentFilter === 'pending')   return !t.completed;
    if (currentFilter === 'completed') return t.completed;
    return true;
  });

  taskList.innerHTML = filtered.length
    ? filtered.map(t => `
        <li class="task-item priority-${t.priority} ${t.completed ? 'completed' : ''}" data-id="${t.id}">
          <input type="checkbox" ${t.completed ? 'checked' : ''} />
          <span class="task-text">${escapeHtml(t.text)}</span>
          <span class="task-date">${formatDate(t.createdAt)}</span>
          <button class="delete-btn" title="Elimina">✕</button>
        </li>`).join('')
    : '<li style="text-align:center;color:#555;padding:1rem">Nessuna task 🎉</li>';

  const pending = tasks.filter(t => !t.completed).length;
  taskCount.textContent = `${pending} task rimanent${pending === 1 ? 'e' : 'i'}`;
}

// Prevenire XSS
function escapeHtml(str) {
  return str.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

// ── Event listeners ────────────────────────────────────
addBtn.addEventListener('click', addTask);

taskInput.addEventListener('keydown', e => {
  if (e.key === 'Enter') addTask();
});

taskList.addEventListener('click', e => {
  const li = e.target.closest('.task-item');
  if (!li) return;
  const id = Number(li.dataset.id);
  if (e.target.matches('input[type="checkbox"]')) toggleTask(id);
  if (e.target.matches('.delete-btn'))            deleteTask(id);
});

filterBtns.forEach(btn => {
  btn.addEventListener('click', () => {
    filterBtns.forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    currentFilter = btn.dataset.filter;
    render();
  });
});

clearCompleted.addEventListener('click', clearDone);

// ── Init ───────────────────────────────────────────────
render();
