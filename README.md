# Replace your player_outfits table in the database with the one provided here

**In qb-apartments/client/main.lua at line 81 replace:**

```TriggerEvent('qb-clothing:client:openOutfitMenu')```

with

```TriggerEvent('cui_wardrobe:open')```

**In qb-houses/client/main.lua at line 338 replace:**

```TriggerEvent('qb-clothing:client:openOutfitMenu')```

with

```TriggerEvent('cui_wardrobe:open')```
