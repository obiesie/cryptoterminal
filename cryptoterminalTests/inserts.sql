
INSERT INTO ADDRESS_TYPE(TYPE) VALUES('ERC20');
INSERT INTO CURRENCY_TYPE(TYPE) VALUES('FIAT');
INSERT INTO CURRENCY_TYPE(TYPE) VALUES('CRYPTO');

INSERT INTO CURRENCY(NAME, CODE, TYPE, ADDRESS_TYPE) VALUES('Botswana pula','BWP',1,null);
INSERT INTO CURRENCY(NAME, CODE, TYPE, IS_EXCHANGE_CURRENCY,ADDRESS_TYPE) VALUES('UK Pound sterling','GBP',1, 1,null);
INSERT INTO CURRENCY(NAME, CODE, TYPE, IS_EXCHANGE_CURRENCY,ADDRESS_TYPE) VALUES('United States dollar','USD',1, 1, null);
INSERT INTO CURRENCY(NAME, CODE, TYPE, IS_EXCHANGE_CURRENCY, ADDRESS_TYPE) VALUES('Euro','EUR',1, 1, null);
INSERT INTO CURRENCY(NAME, CODE, TYPE, IS_EXCHANGE_CURRENCY, ADDRESS_TYPE) VALUES('Japanese Yen','JPY',1,1, null);
INSERT INTO CURRENCY(NAME, CODE, TYPE, IS_EXCHANGE_CURRENCY, ADDRESS_TYPE) VALUES('South Korean won','KRW',1, 1, null);
INSERT INTO CURRENCY(NAME, CODE, TYPE, IS_EXCHANGE_CURRENCY, ADDRESS_TYPE) VALUES('Swiss franc','CHF',1,1, null);

INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE, IS_EXCHANGE_CURRENCY) VALUES('Ethereum','ETH', 2,'https://api.etherscan.io/api?module=account&action=balance&address={}&tag=latest&apikey=SFUJUSGCDN6B9FXIEUYWAMWYSTJYJT2A1X','result','18', 1, 1);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE, IS_EXCHANGE_CURRENCY) VALUES('Bitcoin','BTC',2,'https://blockexplorer.com/api/addr/{}','balance','0', null, 1);


INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Bitcoin Cash','BCH',2,'https://bitcoincash.blockexplorer.com/api/addr/{}/?noTxList=1','balance','0', NULL);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Ripple','XRP',2, null, null,null, NULL);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Litecoin','LTC',2,'https://insight.litecore.io/api/addr/{}','balance','0', NULL);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Cardano','ADA',2,'https://cardanoexplorer.com/api/addresses/summary/{}','Right,caBalance,getCoin','0', NULL);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('NEO','NEO',2,null,null,null, NULL);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Stellar','XLM',2,null,null,null, NULL);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('IOTA','MIOTA',2,null,null,null, NULL);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Dash','DASH',2,'https://explorer.dash.org/chain/Dash/q/addressbalance/{}','raw',0, NULL);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Monero','XMR',2, null,null,null, NULL);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Zcash','ZEC',2,'https://zcash.blockexplorer.com/api/addr/{}','balance','0', NULL);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Decred','DCR',2,'https://mainnet.decred.org/api/addr/{}','balance','0',NULL);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Stratis','STRAT',2,'https://chainz.cryptoid.info/strat/api.dws?q=getbalance&a={}','raw','0', NULL);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Dogecoin','DOGE',2,'https://dogechain.info/api/v1/address/balance/{}&tag=latest&apikey=SFUJUSGCDN6B9FXIEUYWAMWYSTJYJT2A1X','balance','0', NULL);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Factom','FACT',2,null,null,null, NULL);

INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Augur','REP',2,'https://api.etherscan.io/api?module=account&action=tokenbalance&contractaddress=0xE94327D07Fc17907b4DB788E5aDf2ed424adDff6&address={}&tag=latest&apikey=SFUJUSGCDN6B9FXIEUYWAMWYSTJYJT2A1X','result','18',1);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Aragon Network Token','ANT',2,'https://api.etherscan.io/api?module=account&action=tokenbalance&contractaddress=0x960b236A07cf122663c4303350609A66A7B288C0&address={}&tag=latest&apikey=SFUJUSGCDN6B9FXIEUYWAMWYSTJYJT2A1X','result','18',1);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Kyber Network Crystal','KNC',2,'https://api.etherscan.io/api?module=account&action=tokenbalance&contractaddress=0xdd974D5C2e2928deA5F71b9825b8b646686BD200&address={}&tag=latest&apikey=SFUJUSGCDN6B9FXIEUYWAMWYSTJYJT2A1X','result','18',1);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Golem','GNT',2,'https://api.etherscan.io/api?module=account&action=tokenbalance&contractaddress=0xa74476443119A942dE498590Fe1f2454d7D4aC0d&address={}&tag=latest&apikey=SFUJUSGCDN6B9FXIEUYWAMWYSTJYJT2A1X','result','18',1);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Request Network','REQ',2,'https://api.etherscan.io/api?module=account&action=tokenbalance&contractaddress=0x8f8221aFbB33998d8584A2B05749bA73c37a938a&address={}&tag=latest&apikey=SFUJUSGCDN6B9FXIEUYWAMWYSTJYJT2A1X','result','18',1);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Icon','ICX',2,'https://api.etherscan.io/api?module=account&action=tokenbalance&contractaddress=0xb5a5f22694352c15b00323844ad545abb2b11028&address={}&tag=latest&apikey=SFUJUSGCDN6B9FXIEUYWAMWYSTJYJT2A1X','result','18',1);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('OmiseGo','OMG',2,'https://api.etherscan.io/api?module=account&action=tokenbalance&contractaddress=0xd26114cd6EE289AccF82350c8d8487fedB8A0C07&address={}&tag=latest&apikey=SFUJUSGCDN6B9FXIEUYWAMWYSTJYJT2A1X','result','18',1);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('0x','ZRX',2,'https://api.etherscan.io/api?module=account&action=tokenbalance&contractaddress=0xE41d2489571d322189246DaFA5ebDe1F4699F498&address={}&tag=latest&apikey=SFUJUSGCDN6B9FXIEUYWAMWYSTJYJT2A1X','result','18',1);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('Basic Attention Token','BAT',2,'https://api.etherscan.io/api?module=account&action=tokenbalance&contractaddress=0x0D8775F648430679A709E98d2b0Cb6250d2887EF&address={}&tag=latest&apikey=SFUJUSGCDN6B9FXIEUYWAMWYSTJYJT2A1X','result','18',1);
INSERT INTO CURRENCY(NAME, CODE, TYPE, BALANCE_ENDPOINT,BALANCE_RESPONSE_PATH, BALANCE_DECIMAL_PLACE, ADDRESS_TYPE) VALUES('SelfKey','KEY',2,'https://api.etherscan.io/api?module=account&action=tokenbalance&contractaddress=0x4CC19356f2D37338b9802aa8E8fc58B0373296E7&address={}&tag=latest&apikey=SFUJUSGCDN6B9FXIEUYWAMWYSTJYJT2A1X','result','18',1);


INSERT INTO EXCHANGE(NAME, API) VALUES ('COINBASE','https://api.coinbase.com/v2/');
INSERT INTO EXCHANGE(NAME, API) VALUES ('GDAX','https://api-public.gdax.com');
INSERT INTO EXCHANGE(NAME, API) VALUES ('GEMINI','https://api.gemini.com/v1/symbols');
