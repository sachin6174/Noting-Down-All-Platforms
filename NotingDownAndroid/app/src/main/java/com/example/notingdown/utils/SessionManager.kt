package com.example.notingdown.utils

import android.content.Context
import android.content.SharedPreferences
import com.example.notingdown.data.User
import com.google.gson.Gson

class SessionManager(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val gson = Gson()

    companion object {
        private const val PREFS_NAME = "noting_down_session"
        private const val KEY_IS_LOGGED_IN = "is_logged_in"
        private const val KEY_USER_DATA = "user_data"
    }

    fun saveUser(user: User) {
        val editor = prefs.edit()
        editor.putBoolean(KEY_IS_LOGGED_IN, true)
        editor.putString(KEY_USER_DATA, gson.toJson(user))
        editor.apply()
    }

    fun getUser(): User? {
        val userJson = prefs.getString(KEY_USER_DATA, null)
        return if (userJson != null) {
            gson.fromJson(userJson, User::class.java)
        } else null
    }

    fun isLoggedIn(): Boolean {
        return prefs.getBoolean(KEY_IS_LOGGED_IN, false)
    }

    fun clearSession() {
        val editor = prefs.edit()
        editor.clear()
        editor.apply()
    }
}