import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DateTime } from 'luxon';
import { ApiException } from '../common/exceptions/api.exception';
import { ErrorCode } from '../common/enums/error-code.enum';

export interface CutoffResult {
  cutoffAtUtc: string;
  isPassed: boolean;
  remainingMs: number;
}

@Injectable()
export class CutoffService {
  private readonly logger = new Logger(CutoffService.name);
  private readonly defaultHour: number;
  private readonly defaultMinute: number;
  private readonly defaultTimezone: string;

  constructor(private readonly configService: ConfigService) {
    this.defaultHour = parseInt(
      this.configService.get<string>('CUTOFF_HOUR', '20'),
      10,
    );
    this.defaultMinute = parseInt(
      this.configService.get<string>('CUTOFF_MINUTE', '30'),
      10,
    );
    this.defaultTimezone = this.configService.get<string>(
      'DEFAULT_TIMEZONE',
      'Asia/Kolkata',
    );
  }

  /**
   * Calculates the UTC cutoff timestamp for a given delivery date and timezone.
   * Cutoff is strictly at [cutoffHour]:[cutoffMinute] on the calendar day BEFORE deliveryDate
   * in the customer's specified IANA timezone.
   *
   * @param deliveryDate "YYYY-MM-DD" local calendar date
   * @param timezone IANA timezone, e.g. "Asia/Kolkata", "America/New_York"
   * @param hour Optional custom cutoff hour (0-23)
   * @param minute Optional custom cutoff minute (0-59)
   */
  public getCutoffDetails(
    deliveryDate: string,
    timezone?: string,
    hour?: number,
    minute?: number,
    nowUtc?: DateTime,
  ): CutoffResult {
    const tz = timezone && DateTime.now().setZone(timezone).isValid ? timezone : this.defaultTimezone;
    const h = hour !== undefined ? hour : this.defaultHour;
    const m = minute !== undefined ? minute : this.defaultMinute;

    // Parse the deliveryDate as a calendar date in the target timezone
    const parsedDate = DateTime.fromISO(deliveryDate, { zone: tz });
    if (!parsedDate.isValid) {
      throw new ApiException(
        ErrorCode.INVALID_DATE,
        `Invalid delivery date format: ${deliveryDate}. Expected YYYY-MM-DD.`,
      );
    }

    // Cutoff is the previous calendar day at cutoff hour & minute in customer's local timezone
    const cutoffLocal = parsedDate
      .minus({ days: 1 })
      .set({ hour: h, minute: m, second: 0, millisecond: 0 });

    const cutoffUtc = cutoffLocal.toUTC();
    const cutoffAtUtc = cutoffUtc.toISO() ?? cutoffUtc.toJSDate().toISOString();

    const currentUtc = nowUtc ?? DateTime.now().toUTC();
    const remainingMs = cutoffUtc.diff(currentUtc).as('milliseconds');
    const isPassed = remainingMs <= 0;

    return {
      cutoffAtUtc,
      isPassed,
      remainingMs: Math.max(0, remainingMs),
    };
  }

  /**
   * Validates that the cutoff for a delivery date has not passed.
   * Throws HTTP 400 ApiException(EDIT_CUTOFF_PASSED) if passed.
   */
  public validateCutoffOrThrow(
    deliveryDate: string,
    timezone?: string,
    hour?: number,
    minute?: number,
  ): string {
    const { cutoffAtUtc, isPassed } = this.getCutoffDetails(
      deliveryDate,
      timezone,
      hour,
      minute,
    );

    if (isPassed) {
      throw new ApiException(
        ErrorCode.EDIT_CUTOFF_PASSED,
        'Edits are no longer allowed for this order as the edit cutoff time has passed.',
        400,
        cutoffAtUtc,
      );
    }

    return cutoffAtUtc;
  }
}
