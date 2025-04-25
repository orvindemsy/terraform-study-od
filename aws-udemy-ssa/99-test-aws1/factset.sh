export FACTSET_USERNAME=ALPTECH-1643586
export FACTSET_PASSWORD=ypmHoW5EdI5yCMXBJSOq8Jy9bBaVgi15UqRbczqk


curl -X POST \
  -u "$FACTSET_USERNAME:$FACTSET_PASSWORD" \
  -H "Content-Type: application/json" \
  -d '{
        "data": {
            "universe": "ISON_ETP_CONST(QQQ-US,20250226)",
            "formulas": [
                "FSYM_SEDOL",
                "FSYM_SECURITY_PERM_ID",
                "ETP_CONST_DATE(QQQ-US,20250226,DATEN)",
                "PROPER_NAME(0,SECURITY,NAME)",
                "FSYM_BLOOMBERG_ID(LISTING)",
                "FSYM_BLOOMBERG_ID(SECURITY)",
                "FSYM_BLOOMBERG_ID(COMPOSITE)",
		"FSYM_ENTITY_ID",
                "FSYM_TICKER_EXCHANGE",
                "FSYM_BLOOMBERG_ID(COMPOSITE)",
                "ETP_CONST_WEIGHT(QQQ-US,20250226)"
            ],
            "displayName": [
                "FSYM_SEDOL",
                "FSYM_SECURITY_PERM_ID",
                "ETP_CONST_DATE",
                "PROPER_NAME",
                "LISTING_FIGI",
                "SHARECLASS_FIGI",
                "COMPOSITE_FIGI",
		"FSYM_ENTITY_ID",
                "FSYM_TICKER_EXCHANGE",
                "FSYM_BLOOMBERG_ID",
                "ETP_CONST_WEIGHT"
            ],
            "flatten": "Y"
        }
    }' \
  https://api.factset.com/formula-api/v1/cross-sectional
