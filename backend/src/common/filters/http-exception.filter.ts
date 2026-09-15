import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Response } from 'express';
import { ErrorCode } from '../enums/error-code.enum';

@Catch()
export class GlobalHttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalHttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let code: string = ErrorCode.INTERNAL_ERROR;
    let message = 'An unexpected server error occurred.';
    let cutoffAt: string | undefined = undefined;
    let details: any = undefined;

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const res = exception.getResponse();

      if (typeof res === 'object' && res !== null) {
        const resObj = res as any;
        code = resObj.code || (status === 404 ? 'NOT_FOUND' : 'BAD_REQUEST');
        message =
          Array.isArray(resObj.message) ? resObj.message.join(', ') : resObj.message || exception.message;
        cutoffAt = resObj.cutoffAt;
        details = resObj.details;
      } else {
        message = String(res);
      }
    } else if (exception instanceof Error) {
      this.logger.error(`Unhandled Exception: ${exception.message}`, exception.stack);
      message = exception.message;
    }

    const payload: any = {
      statusCode: status,
      code,
      message,
    };

    if (cutoffAt) {
      payload.cutoffAt = cutoffAt;
    }
    if (details) {
      payload.details = details;
    }

    response.status(status).json(payload);
  }
}
