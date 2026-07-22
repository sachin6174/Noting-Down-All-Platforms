package com.example.notingdown.viewmodel

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.notingdown.data.Note
import com.example.notingdown.data.NoteRequest
import com.example.notingdown.network.ApiClient
import kotlinx.coroutines.launch

class NoteViewModel : ViewModel() {
    private val apiService = ApiClient.getInstance().apiService
    
    private val _notes = MutableLiveData<List<Note>>()
    val notes: LiveData<List<Note>> = _notes

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    private val _error = MutableLiveData<String>()
    val error: LiveData<String> = _error

    private val _deleteResult = MutableLiveData<Boolean>()
    val deleteResult: LiveData<Boolean> = _deleteResult

    private val _noteResult = MutableLiveData<Result<Note>>()
    val noteResult: LiveData<Result<Note>> = _noteResult

    suspend fun loadNotes() {
        _isLoading.value = true
        _error.value = ""
        
        try {
            val response = apiService.getNotes()
            if (response.isSuccessful && response.body() != null) {
                val notesResponse = response.body()!!
                if (notesResponse.success) {
                    _notes.value = notesResponse.notes
                } else {
                    _error.value = "Failed to load notes"
                }
            } else {
                _error.value = "Network error: ${response.message()}"
            }
        } catch (e: Exception) {
            _error.value = "Error loading notes: ${e.message}"
        } finally {
            _isLoading.value = false
        }
    }

    suspend fun searchNotes(query: String) {
        _isLoading.value = true
        _error.value = ""
        
        try {
            val response = apiService.getNotes(search = query)
            if (response.isSuccessful && response.body() != null) {
                val notesResponse = response.body()!!
                if (notesResponse.success) {
                    _notes.value = notesResponse.notes
                } else {
                    _error.value = "Failed to search notes"
                }
            } else {
                _error.value = "Network error: ${response.message()}"
            }
        } catch (e: Exception) {
            _error.value = "Error searching notes: ${e.message}"
        } finally {
            _isLoading.value = false
        }
    }

    suspend fun deleteNote(noteId: String) {
        try {
            val response = apiService.deleteNote(noteId)
            if (response.isSuccessful && response.body() != null) {
                val deleteResponse = response.body()!!
                _deleteResult.value = deleteResponse.success
                if (!deleteResponse.success) {
                    _error.value = "Failed to delete note"
                }
            } else {
                _error.value = "Network error: ${response.message()}"
                _deleteResult.value = false
            }
        } catch (e: Exception) {
            _error.value = "Error deleting note: ${e.message}"
            _deleteResult.value = false
        }
    }

    suspend fun getNoteById(noteId: String) {
        try {
            val response = apiService.getNoteById(noteId)
            if (response.isSuccessful && response.body() != null) {
                val noteResponse = response.body()!!
                if (noteResponse.success && noteResponse.note != null) {
                    _noteResult.value = Result.success(noteResponse.note)
                } else {
                    _noteResult.value = Result.failure(Exception("Note not found"))
                }
            } else {
                _noteResult.value = Result.failure(Exception("Network error: ${response.message()}"))
            }
        } catch (e: Exception) {
            _noteResult.value = Result.failure(e)
        }
    }

    suspend fun createNote(title: String, content: String) {
        try {
            val response = apiService.createNote(NoteRequest(title, content))
            if (response.isSuccessful && response.body() != null) {
                val noteResponse = response.body()!!
                if (noteResponse.success && noteResponse.note != null) {
                    _noteResult.value = Result.success(noteResponse.note)
                } else {
                    _noteResult.value = Result.failure(Exception(noteResponse.message))
                }
            } else {
                _noteResult.value = Result.failure(Exception("Network error: ${response.message()}"))
            }
        } catch (e: Exception) {
            _noteResult.value = Result.failure(e)
        }
    }

    suspend fun updateNote(noteId: String, title: String, content: String) {
        try {
            val response = apiService.updateNote(noteId, NoteRequest(title, content))
            if (response.isSuccessful && response.body() != null) {
                val noteResponse = response.body()!!
                if (noteResponse.success && noteResponse.note != null) {
                    _noteResult.value = Result.success(noteResponse.note)
                } else {
                    _noteResult.value = Result.failure(Exception(noteResponse.message))
                }
            } else {
                _noteResult.value = Result.failure(Exception("Network error: ${response.message()}"))
            }
        } catch (e: Exception) {
            _noteResult.value = Result.failure(e)
        }
    }

    suspend fun logout() {
        try {
            apiService.logout()
        } catch (e: Exception) {
            // Ignore logout errors as we'll clear session anyway
        }
    }
}
