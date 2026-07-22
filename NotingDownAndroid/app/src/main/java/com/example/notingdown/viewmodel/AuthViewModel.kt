package com.example.notingdown.viewmodel

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.notingdown.data.LoginRequest
import com.example.notingdown.data.LoginResponse
import com.example.notingdown.data.SignupRequest
import com.example.notingdown.network.ApiClient
import kotlinx.coroutines.launch

class AuthViewModel : ViewModel() {
    private val apiService = ApiClient.getInstance().apiService
    
    private val _authResult = MutableLiveData<Result<LoginResponse>>()
    val authResult: LiveData<Result<LoginResponse>> = _authResult

    fun login(email: String, password: String) {
        viewModelScope.launch {
            try {
                val response = apiService.login(LoginRequest(email, password))
                if (response.isSuccessful && response.body() != null) {
                    _authResult.value = Result.success(response.body()!!)
                } else {
                    _authResult.value = Result.failure(Exception("Login failed: ${response.message()}"))
                }
            } catch (e: Exception) {
                _authResult.value = Result.failure(e)
            }
        }
    }

    fun signup(email: String, username: String, password: String) {
        viewModelScope.launch {
            try {
                val response = apiService.signup(SignupRequest(email, username, password))
                if (response.isSuccessful && response.body() != null) {
                    _authResult.value = Result.success(response.body()!!)
                } else {
                    _authResult.value = Result.failure(Exception("Signup failed: ${response.message()}"))
                }
            } catch (e: Exception) {
                _authResult.value = Result.failure(e)
            }
        }
    }
}