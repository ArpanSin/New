package io.flutter.plugins.api

import okhttp3.MultipartBody
import okhttp3.RequestBody
import retrofit2.Response
import retrofit2.http.*

data class RegisterResponse(
    val id: Int?,
    val name: String?,
    val age: Int?,
    val last_seen_location: String?,
    val photo: String?,
    val status: String?
)

data class MatchResponse(
    val match: Boolean,
    val child: Map<String, Any>?
)

interface ApiService {

    @Multipart
    @POST("api/register_child/")
    suspend fun registerChild(
        @Part("name") name: RequestBody,
        @Part("age") age: RequestBody,
        @Part("last_seen_location") lastSeen: RequestBody,
        @Part photo: MultipartBody.Part
    ): Response<RegisterResponse>

    @Multipart
    @POST("api/upload_image/")
    suspend fun uploadImage(
        @Part uploaded_photo: MultipartBody.Part
    ): Response<MatchResponse>
}
