import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { DateTime } from 'luxon';
import { CutoffService } from '../src/cutoff/cutoff.service';
import { ApiException } from '../src/common/exceptions/api.exception';
import { ErrorCode } from '../src/common/enums/error-code.enum';

describe('CutoffService', () => {
  let service: CutoffService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CutoffService,
        {
          provide: ConfigService,
          useValue: {
            get: (key: string, defaultValue: string) => {
              if (key === 'CUTOFF_HOUR') return '20';
              if (key === 'CUTOFF_MINUTE') return '30';
              if (key === 'DEFAULT_TIMEZONE') return 'Asia/Kolkata';
              return defaultValue;
            },
          },
        },
      ],
    }).compile();

    service = module.get<CutoffService>(CutoffService);
  });

  describe('Cutoff Time Calculation & Timezones', () => {
    it('calculates correct UTC cutoff for Asia/Kolkata (UTC+5:30)', () => {
      // Delivery date: 2026-09-16 in Asia/Kolkata
      // Cutoff: 2026-09-15 20:30:00 Asia/Kolkata -> 2026-09-15 15:00:00 UTC
      const deliveryDate = '2026-09-16';
      const timezone = 'Asia/Kolkata';

      const result = service.getCutoffDetails(deliveryDate, timezone, 20, 30);

      // Verify ISO timestamp
      const cutoffDt = DateTime.fromISO(result.cutoffAtUtc).toUTC();
      expect(cutoffDt.year).toBe(2026);
      expect(cutoffDt.month).toBe(9);
      expect(cutoffDt.day).toBe(15);
      expect(cutoffDt.hour).toBe(15);
      expect(cutoffDt.minute).toBe(0);
    });

    it('calculates correct UTC cutoff for America/New_York during Daylight Savings (EDT = UTC-4)', () => {
      // In September, New York is in EDT (UTC-4)
      // Delivery date: 2026-09-20
      // Cutoff: 2026-09-19 20:30:00 EDT -> 2026-09-20 00:30:00 UTC
      const deliveryDate = '2026-09-20';
      const timezone = 'America/New_York';

      const result = service.getCutoffDetails(deliveryDate, timezone, 20, 30);

      const cutoffDt = DateTime.fromISO(result.cutoffAtUtc).toUTC();
      expect(cutoffDt.year).toBe(2026);
      expect(cutoffDt.month).toBe(9);
      expect(cutoffDt.day).toBe(20);
      expect(cutoffDt.hour).toBe(0);
      expect(cutoffDt.minute).toBe(30);
    });

    it('calculates correct UTC cutoff for America/New_York during Standard Time (EST = UTC-5)', () => {
      // In January, New York is in EST (UTC-5)
      // Delivery date: 2027-01-15
      // Cutoff: 2027-01-14 20:30:00 EST -> 2027-01-15 01:30:00 UTC
      const deliveryDate = '2027-01-15';
      const timezone = 'America/New_York';

      const result = service.getCutoffDetails(deliveryDate, timezone, 20, 30);

      const cutoffDt = DateTime.fromISO(result.cutoffAtUtc).toUTC();
      expect(cutoffDt.year).toBe(2027);
      expect(cutoffDt.month).toBe(1);
      expect(cutoffDt.day).toBe(15);
      expect(cutoffDt.hour).toBe(1);
      expect(cutoffDt.minute).toBe(30);
    });
  });

  describe('Cutoff Validation (Passed vs Not Passed)', () => {
    it('allows mutation when current time is before cutoff', () => {
      const deliveryDate = '2026-09-16';
      const timezone = 'Asia/Kolkata';

      // Mock current time: 2026-09-15 14:00:00 UTC (1 hour before 15:00 UTC cutoff)
      const mockNow = DateTime.fromISO('2026-09-15T14:00:00.000Z');

      const result = service.getCutoffDetails(deliveryDate, timezone, 20, 30, mockNow);
      expect(result.isPassed).toBe(false);
      expect(result.remainingMs).toBeGreaterThan(0);
    });

    it('identifies passed cutoff when current time is after cutoff', () => {
      const deliveryDate = '2026-09-16';
      const timezone = 'Asia/Kolkata';

      // Mock current time: 2026-09-15 16:00:00 UTC (1 hour after 15:00 UTC cutoff)
      const mockNow = DateTime.fromISO('2026-09-15T16:00:00.000Z');

      const result = service.getCutoffDetails(deliveryDate, timezone, 20, 30, mockNow);
      expect(result.isPassed).toBe(true);
      expect(result.remainingMs).toBe(0);
    });

    it('throws ApiException with EDIT_CUTOFF_PASSED when validating passed order', () => {
      // Past date whose cutoff is well in the past
      const pastDeliveryDate = '2020-01-01';
      const timezone = 'Asia/Kolkata';

      expect(() => {
        service.validateCutoffOrThrow(pastDeliveryDate, timezone, 20, 30);
      }).toThrow(ApiException);

      try {
        service.validateCutoffOrThrow(pastDeliveryDate, timezone, 20, 30);
      } catch (err: any) {
        expect(err.getStatus()).toBe(400);
        const res = err.getResponse();
        expect(res.code).toBe(ErrorCode.EDIT_CUTOFF_PASSED);
        expect(res.cutoffAt).toBeDefined();
      }
    });
  });
});
