const API_BASE_URL = 'http://localhost:3001/api';

class NotesApp {
  constructor() {
    this.currentUser = null;
    this.notes = [];
    this.filteredNotes = [];
    this.editingNoteId = null;
    this.isLoading = true;
    this.sortBy = 'lastUpdated';
    this.sortOrder = 'desc';
    this.viewMode = 'list';
    this.searchTerm = '';
    this.noteModal = null;
    this.init();
  }

  async init() {
    this.showLoading();
    this.setupEventListeners();
    await this.checkSession();
  }

  setupEventListeners() {
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
      loginForm.addEventListener('submit', (e) => this.handleLogin(e));
    }
    
    const signupForm = document.getElementById('signupForm');
    if (signupForm) {
      signupForm.addEventListener('submit', (e) => this.handleSignup(e));
    }
  }

  setupAppEventListeners() {
    const searchInput = document.getElementById('searchInput');
    if (searchInput) {
      searchInput.addEventListener('input', (e) => this.handleSearch(e));
    }
    
    const sortSelect = document.getElementById('sortSelect');
    if (sortSelect) {
      sortSelect.addEventListener('change', (e) => this.handleSort(e));
    }

    const noteForm = document.getElementById('noteForm');
    if (noteForm) {
        noteForm.addEventListener('submit', (e) => this.handleSaveNote(e));
    }

    this.noteModal = new bootstrap.Modal(document.getElementById('noteModal'));
  }

  async checkSession() {
    try {
      const response = await fetch(`${API_BASE_URL}/auth/session`, {
        method: 'GET',
        credentials: 'include'
      });

      if (response.ok) {
        const data = await response.json();
        this.currentUser = data.user;
        this.hideLoading();
        this.showApp();
        await this.loadNotes();
      } else {
        this.hideLoading();
        this.showAuth();
      }
    } catch (error) {
      console.error('Session check failed:', error);
      this.hideLoading();
      this.showAuth();
    }
  }

  async handleLogin(e) {
    e.preventDefault();
    const formData = new FormData(e.target);
    const email = formData.get('email');
    const password = formData.get('password');

    try {
      const response = await fetch(`${API_BASE_URL}/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include',
        body: JSON.stringify({ email, password })
      });

      const data = await response.json();

      if (data.success) {
        this.currentUser = data.user;
        this.hideLoading();
        this.showApp();
        await this.loadNotes();
      } else {
        this.showMessage('login-message', data.message, 'danger');
      }
    } catch (error) {
      console.error('Login error:', error);
      this.showMessage('login-message', 'Login failed. Please try again.', 'danger');
    }
  }

  async handleSignup(e) {
    e.preventDefault();
    const formData = new FormData(e.target);
    const email = formData.get('email');
    const username = formData.get('username');
    const password = formData.get('password');

    if (!email || !username || !password) {
      this.showMessage('signup-message', 'All fields are required', 'danger');
      return;
    }

    try {
      const response = await fetch(`${API_BASE_URL}/auth/signup`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include',
        body: JSON.stringify({ email, username, password })
      });

      const data = await response.json();

      if (data.success) {
        this.currentUser = data.user;
        this.hideLoading();
        this.showApp();
        await this.loadNotes();
      } else {
        this.showMessage('signup-message', data.message, 'danger');
      }
    } catch (error) {
      console.error('Signup error:', error);
      this.showMessage('signup-message', 'Signup failed. Please try again.', 'danger');
    }
  }

  async handleSaveNote(e) {
    e.preventDefault();
    const title = document.getElementById('noteTitle').value;
    const content = document.getElementById('noteContent').value;
    const noteId = document.getElementById('noteId').value;

    if (!title.trim() || !content.trim()) {
      this.showMessage('app-message', 'Title and content are required', 'danger');
      return;
    }

    try {
      const url = noteId 
        ? `${API_BASE_URL}/notes/${noteId}` 
        : `${API_BASE_URL}/notes`;
      
      const method = noteId ? 'PUT' : 'POST';

      const response = await fetch(url, {
        method: method,
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include',
        body: JSON.stringify({ title, content })
      });

      const data = await response.json();

      if (data.success) {
        this.showMessage('app-message', data.message, 'success');
        this.noteModal.hide();
        await this.loadNotes();
      } else {
        this.showMessage('app-message', data.message, 'danger');
      }
    } catch (error) {
      console.error('Save note error:', error);
      this.showMessage('app-message', 'Failed to save note. Please try again.', 'danger');
    }
  }

  async loadNotes() {
    try {
      const response = await fetch(`${API_BASE_URL}/notes`, {
        method: 'GET',
        credentials: 'include'
      });

      const data = await response.json();

      if (data.success) {
        this.notes = data.notes;
        this.filteredNotes = [...this.notes];
        this.filterAndSortNotes();
      } else {
        this.showMessage('app-message', 'Failed to load notes', 'danger');
      }
    } catch (error) {
      console.error('Load notes error:', error);
      this.showMessage('app-message', 'Failed to load notes. Please refresh the page.', 'danger');
    }
  }

  async deleteNote(noteId) {
    if (!confirm('Are you sure you want to delete this note?')) {
      return;
    }

    try {
      const response = await fetch(`${API_BASE_URL}/notes/${noteId}`, {
        method: 'DELETE',
        credentials: 'include'
      });

      const data = await response.json();

      if (data.success) {
        this.showMessage('app-message', 'Note deleted successfully', 'success');
        await this.loadNotes();
      } else {
        this.showMessage('app-message', data.message, 'danger');
      }
    } catch (error) {
      console.error('Delete note error:', error);
      this.showMessage('app-message', 'Failed to delete note. Please try again.', 'danger');
    }
  }

  async logout() {
    this.showLoading();
    try {
      await fetch(`${API_BASE_URL}/auth/logout`, {
        method: 'POST',
        credentials: 'include'
      });
    } catch (error) {
      console.error('Logout error:', error);
    }
    
    this.currentUser = null;
    this.notes = [];
    this.showAuth();
  }

  handleSearch(e) {
    this.searchTerm = e.target.value.toLowerCase();
    this.filterAndSortNotes();
  }

  handleSort(e) {
    this.sortBy = e.target.value;
    this.filterAndSortNotes();
  }

  filterAndSortNotes() {
    this.filteredNotes = this.notes.filter(note => {
      if (!this.searchTerm) return true;
      return (
        note.title.toLowerCase().includes(this.searchTerm) ||
        note.content.toLowerCase().includes(this.searchTerm)
      );
    });

    this.filteredNotes.sort((a, b) => {
      let aValue = a[this.sortBy];
      let bValue = b[this.sortBy];

      if (this.sortBy === 'title') {
        aValue = aValue.toLowerCase();
        bValue = bValue.toLowerCase();
      } else if (this.sortBy === 'lastUpdated' || this.sortBy === 'createdAt') {
        aValue = new Date(aValue);
        bValue = new Date(bValue);
      }

      if (this.sortOrder === 'desc') {
        return aValue > bValue ? -1 : aValue < bValue ? 1 : 0;
      } else {
        return aValue < bValue ? -1 : aValue > bValue ? 1 : 0;
      }
    });

    this.renderNotes();
  }

  renderNotes() {
    const notesList = document.getElementById('notes-list');
    const noNotes = document.getElementById('no-notes');
    
    notesList.className = `row ${this.viewMode === 'grid' ? 'row-cols-1 row-cols-md-3 g-4' : 'row-cols-1'}`;

    if (this.filteredNotes.length === 0) {
      notesList.innerHTML = '';
      noNotes.classList.remove('d-none');
      return;
    }

    noNotes.classList.add('d-none');
    notesList.innerHTML = this.filteredNotes.map(note => {
        const colClass = this.viewMode === 'grid' ? 'col' : 'col-12 mb-3';
        return `
          <div class="${colClass}">
            <div class="card h-100 note-item" onclick="app.editNote('${note.id}')">
              <div class="card-body">
                <h5 class="card-title">${this.escapeHtml(note.title)}</h5>
                <p class="card-text">${this.escapeHtml(note.content)}</p>
              </div>
              <div class="card-footer d-flex justify-content-between align-items-center">
                <small class="text-muted">Last updated: ${new Date(note.lastUpdated).toLocaleDateString()}</small>
                <button class="btn btn-sm btn-outline-danger" onclick="event.stopPropagation(); app.deleteNote('${note.id}')"><i class="bi bi-trash"></i></button>
              </div>
            </div>
          </div>
        `
    }).join('');
  }

  editNote(noteId) {
    const note = this.notes.find(n => n.id === noteId);
    if (!note) return;

    this.editingNoteId = noteId;
    document.getElementById('form-title').textContent = 'Edit Note';
    document.getElementById('noteId').value = noteId;
    document.getElementById('noteTitle').value = note.title;
    document.getElementById('noteContent').value = note.content;
    document.getElementById('saveBtn').textContent = 'Update Note';
    this.noteModal.show();
  }

  showCreateNote() {
    this.editingNoteId = null;
    document.getElementById('form-title').textContent = 'Create New Note';
    document.getElementById('noteForm').reset();
    document.getElementById('noteId').value = '';
    document.getElementById('saveBtn').textContent = 'Save Note';
    this.noteModal.show();
  }

  showLoading() {
    document.getElementById('loading-section').classList.remove('d-none');
    document.getElementById('auth-section').classList.add('d-none');
    document.getElementById('app-section').classList.add('d-none');
  }

  hideLoading() {
    document.getElementById('loading-section').classList.add('d-none');
  }

  showAuth() {
    this.hideLoading();
    document.getElementById('auth-section').classList.remove('d-none');
    document.getElementById('app-section').classList.add('d-none');
  }

  showApp() {
    this.hideLoading();
    document.getElementById('auth-section').classList.add('d-none');
    document.getElementById('app-section').classList.remove('d-none');
    document.getElementById('username').textContent = this.currentUser.username;
    
    this.setupAppEventListeners();
  }

  switchAuthTab(tab) {
    const authTabs = document.getElementById('auth-tabs');
    const loginTab = authTabs.querySelector('a[onclick*="login"]');
    const signupTab = authTabs.querySelector('a[onclick*="signup"]');
    const loginSchema = document.getElementById('login-schema');
    const signupSchema = document.getElementById('signup-schema');

    loginTab.classList.toggle('active', tab === 'login');
    signupTab.classList.toggle('active', tab === 'signup');

    loginSchema.classList.toggle('d-none', tab !== 'login');
    signupSchema.classList.toggle('d-none', tab !== 'signup');

    document.getElementById('login-message').innerHTML = '';
    document.getElementById('signup-message').innerHTML = '';
  }

  showMessage(elementId, message, type) {
    const element = document.getElementById(elementId);
    element.innerHTML = `<div class="alert alert-${type}">${message}</div>`;
    setTimeout(() => {
      if (element.innerHTML.includes(message)) {
        element.innerHTML = '';
      }
    }, 5000);
  }

  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
}

const app = new NotesApp();

function switchTab(tab) {
  app.switchAuthTab(tab);
}

function showCreateNote() {
  app.showCreateNote();
}

function logout() {
  app.logout();
}

function toggleSortOrder() {
  app.sortOrder = app.sortOrder === 'desc' ? 'asc' : 'desc';
  const sortBtn = document.getElementById('sortOrder');
  sortBtn.textContent = app.sortOrder === 'desc' ? '↓' : '↑';
  app.filterAndSortNotes();
}

function setViewMode(mode) {
  app.viewMode = mode;
  
  document.getElementById('listViewBtn').classList.toggle('active', mode === 'list');
  document.getElementById('gridViewBtn').classList.toggle('active', mode === 'grid');
  
  app.renderNotes();
}
