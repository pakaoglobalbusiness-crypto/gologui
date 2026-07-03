// Abstraction de l'agrégateur de paiement (spec §4.2 : PayDunya, CinetPay
// ou Paystack). Le service métier ne connaît que cette interface ; le
// fournisseur est choisi par la variable d'environnement PAYMENT_PROVIDER.

export interface InitiateResult {
  aggregatorRef: string; // référence chez l'agrégateur
  paymentUrl: string; // URL de redirection (checkout) ou deep-link
}

export interface PaymentProvider {
  readonly name: string;
  /** Crée la transaction chez l'agrégateur et renvoie l'URL de paiement. */
  initiate(params: {
    reference: string; // notre référence interne, reprise dans le webhook
    amountFcfa: number;
    method: string; // wave | orange_money | free_money | carte
    description: string;
    customerPhone: string;
  }): Promise<InitiateResult>;
  /** Vérifie l'authenticité d'un webhook entrant. */
  verifyWebhook(headers: Record<string, string>, rawBody: string): boolean;
}
