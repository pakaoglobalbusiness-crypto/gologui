// Valeurs de statut et constantes métier — SQLite ne supportant pas les enums,
// elles sont centralisées ici et validées dans les DTO/services.

export const COMMISSION_RATE = 0.10; // 10 % côté propriétaire (décision validée)
export const OTP_MAX_ATTEMPTS = 5;
export const OTP_TTL_MINUTES = 5;
export const BOOKING_ACCEPT_DEADLINE_HOURS = 24;

export const LISTING_TYPES = ['villa', 'voiture'] as const;
export const LISTING_STATUSES = ['draft', 'in_moderation', 'published', 'suspended'] as const;
export const CANCELLATION_POLICIES = ['flexible', 'moderate', 'strict'] as const;
export const PAYMENT_METHODS = ['wave', 'orange_money', 'free_money', 'carte'] as const;
export const CITIES = ['Dakar', 'Saly', 'Mbour', 'Saint-Louis', 'Touba', 'Ziguinchor'] as const;

export const BOOKING_STATUSES = [
  'requested', 'accepted', 'paid', 'ongoing',
  'completed', 'cancelled', 'disputed', 'rejected', 'expired',
] as const;

// Transitions autorisées de la machine à états des réservations
export const BOOKING_TRANSITIONS: Record<string, string[]> = {
  requested: ['accepted', 'rejected', 'expired', 'cancelled'],
  accepted: ['paid', 'cancelled', 'expired'],
  paid: ['ongoing', 'cancelled', 'disputed'],
  ongoing: ['completed', 'disputed'],
  disputed: ['completed', 'cancelled'],
};

// Barème de remboursement selon la politique, en % du total,
// indexé par le délai avant le début (en jours).
export function refundPercent(policy: string, daysBeforeStart: number): number {
  switch (policy) {
    case 'flexible':
      return daysBeforeStart >= 1 ? 100 : 50;
    case 'moderate':
      if (daysBeforeStart >= 5) return 100;
      return daysBeforeStart >= 1 ? 50 : 0;
    case 'strict':
      if (daysBeforeStart >= 14) return 100;
      return daysBeforeStart >= 7 ? 50 : 0;
    default:
      return 0;
  }
}
