import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:app_template/core/network/api_routes.dart';
import 'package:app_template/features/auth/data/models/auth_api_models.dart';
import 'package:app_template/features/auth/data/models/user_model.dart';
import 'package:app_template/features/auth/data/models/verify_otp_response.dart';

part 'auth_api_service.g.dart';

@RestApi()
abstract class AuthApiService {
  factory AuthApiService(Dio dio) = _AuthApiService;

  @POST(ApiRoutes.sendOtp)
  Future<HttpResponse<dynamic>> sendOtp(
    @Path('tenantCode') String tenantCode,
    @Body() SendOtpRequest body,
  );

  @POST(ApiRoutes.verifyOtp)
  Future<VerifyOtpResponse> verifyOtp(
    @Path('tenantCode') String tenantCode,
    @Body() VerifyOtpRequest body,
  );

  @POST(ApiRoutes.truecaller)
  Future<VerifyOtpResponse> verifyTruecaller(
    @Path('tenantCode') String tenantCode,
    @Body() VerifyTruecallerRequest body,
  );

  @POST(ApiRoutes.refreshToken)
  Future<AuthTokens> refreshToken(
    @Path('tenantCode') String tenantCode,
    @Body() RefreshTokenRequest body,
  );

  @GET(ApiRoutes.profileByPhone)
  Future<UserModel> getProfileByPhone(
    @Path('tenantCode') String tenantCode, {
    @Query('phone') required String phone,
  });

  @GET(ApiRoutes.profileByUserId)
  Future<UserModel> getProfileByUserId(
    @Path('tenantCode') String tenantCode,
    @Path('userId') String userId,
  );
}
