package com.example.notingdown

import android.content.Intent
import android.os.Bundle
import android.view.View
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.example.notingdown.databinding.ActivityAuthBinding
import com.example.notingdown.utils.SessionManager
import com.example.notingdown.viewmodel.AuthViewModel
import com.google.android.material.snackbar.Snackbar
import kotlinx.coroutines.launch

class AuthActivity : AppCompatActivity() {
    private lateinit var binding: ActivityAuthBinding
    private val authViewModel: AuthViewModel by viewModels()
    private lateinit var sessionManager: SessionManager
    private var isLoginMode = true

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAuthBinding.inflate(layoutInflater)
        setContentView(binding.root)

        sessionManager = SessionManager(this)

        if (sessionManager.isLoggedIn()) {
            navigateToMain()
            return
        }

        setupUI()
        setupObservers()
    }

    private fun setupUI() {
        binding.apply {
            btnSubmit.setOnClickListener {
                if (isLoginMode) {
                    handleLogin()
                } else {
                    handleSignup()
                }
            }

            tvSwitchMode.setOnClickListener {
                switchMode()
            }

            btnSwitchToSignup.setOnClickListener {
                switchMode()
            }

            btnSwitchToLogin.setOnClickListener {
                switchMode()
            }
        }

        updateUI()
    }

    private fun setupObservers() {
        authViewModel.authResult.observe(this) { result ->
            binding.progressBar.visibility = View.GONE
            binding.btnSubmit.isEnabled = true

            result.fold(
                onSuccess = { response ->
                    if (response.success && response.user != null) {
                        sessionManager.saveUser(response.user)
                        navigateToMain()
                    } else {
                        showError(response.message)
                    }
                },
                onFailure = { error ->
                    showError(error.message ?: "Authentication failed")
                }
            )
        }
    }

    private fun handleLogin() {
        val email = binding.etEmail.text.toString().trim()
        val password = binding.etPassword.text.toString()

        if (validateLoginInput(email, password)) {
            binding.progressBar.visibility = View.VISIBLE
            binding.btnSubmit.isEnabled = false

            lifecycleScope.launch {
                authViewModel.login(email, password)
            }
        }
    }

    private fun handleSignup() {
        val email = binding.etEmail.text.toString().trim()
        val username = binding.etUsername.text.toString().trim()
        val password = binding.etPassword.text.toString()

        if (validateSignupInput(email, username, password)) {
            binding.progressBar.visibility = View.VISIBLE
            binding.btnSubmit.isEnabled = false

            lifecycleScope.launch {
                authViewModel.signup(email, username, password)
            }
        }
    }

    private fun validateLoginInput(email: String, password: String): Boolean {
        return when {
            email.isEmpty() -> {
                showError("Please enter your email")
                false
            }
            password.isEmpty() -> {
                showError("Please enter your password")
                false
            }
            !android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches() -> {
                showError("Please enter a valid email address")
                false
            }
            else -> true
        }
    }

    private fun validateSignupInput(email: String, username: String, password: String): Boolean {
        return when {
            email.isEmpty() -> {
                showError("Please enter your email")
                false
            }
            username.isEmpty() -> {
                showError("Please enter a username")
                false
            }
            password.isEmpty() -> {
                showError("Please enter a password")
                false
            }
            password.length < 6 -> {
                showError("Password must be at least 6 characters")
                false
            }
            !android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches() -> {
                showError("Please enter a valid email address")
                false
            }
            else -> true
        }
    }

    private fun switchMode() {
        isLoginMode = !isLoginMode
        updateUI()
        clearForm()
    }

    private fun updateUI() {
        binding.apply {
            if (isLoginMode) {
                tvTitle.text = "Sign In"
                etUsername.visibility = View.GONE
                btnSubmit.text = "Sign In"
                tvSwitchPrompt.text = "Don't have an account?"
                tvSwitchMode.text = "Create Account"
                btnSwitchToSignup.visibility = View.VISIBLE
                btnSwitchToLogin.visibility = View.GONE
            } else {
                tvTitle.text = "Create Account"
                etUsername.visibility = View.VISIBLE
                btnSubmit.text = "Create Account"
                tvSwitchPrompt.text = "Already have an account?"
                tvSwitchMode.text = "Sign In"
                btnSwitchToSignup.visibility = View.GONE
                btnSwitchToLogin.visibility = View.VISIBLE
            }
        }
    }

    private fun clearForm() {
        binding.apply {
            etEmail.text?.clear()
            etUsername.text?.clear()
            etPassword.text?.clear()
        }
    }

    private fun showError(message: String) {
        Snackbar.make(binding.root, message, Snackbar.LENGTH_LONG).show()
    }

    private fun navigateToMain() {
        val intent = Intent(this, MainActivity::class.java)
        startActivity(intent)
        finish()
    }
}