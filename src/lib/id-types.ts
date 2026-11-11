/** Nigerian ID documents accepted for seller verification. */
export const ID_TYPES = {
  nin: "NIN slip or card",
  drivers_licence: "Driver's licence",
  international_passport: "International passport",
  voters_card: "Voter's card",
} as const;

export type IdType = keyof typeof ID_TYPES;
