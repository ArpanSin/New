package io.flutter.plugins.api

import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody
import java.io.File

fun createPartFromString(value: String): RequestBody {
    return RequestBody.create("text/plain".toMediaTypeOrNull(), value)
}

fun prepareFilePart(partName: String, file: File): MultipartBody.Part {
    val requestFile = RequestBody.create("image/*".toMediaTypeOrNull(), file)
    return MultipartBody.Part.createFormData(partName, file.name, requestFile)
}
