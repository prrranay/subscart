import { HttpException, HttpStatus } from '@nestjs/common';
import { ErrorCode } from '../enums/error-code.enum';

export interface ApiExceptionPayload {
  statusCode: number;
  code: ErrorCode | string;
  message: string;
  cutoffAt?: string;
  details?: any;
}

export class ApiException extends HttpException {
  constructor(
    code: ErrorCode | string,
    message: string,
    status: HttpStatus = HttpStatus.BAD_REQUEST,
    cutoffAt?: string,
    details?: any,
  ) {
    const response: ApiExceptionPayload = {
      statusCode: status,
      code,
      message,
      ...(cutoffAt ? { cutoffAt } : {}),
      ...(details ? { details } : {}),
    };
    super(response, status);
  }
}
