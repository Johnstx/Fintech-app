db = db.getSiblingDB('fundwavedb');

// Create a collection for accounts
db.createCollection('accounts');

// Insert sample account data
db.accounts.insertMany([
  {
    name: 'John Ukiwe',
    accountNumber: '1234567890',
    balance: 5000
  },
  {
    name: 'Inyiri Anya',
    accountNumber: '0987654321',
    balance: 35000
  },
  {
    name: 'John Doe',
    accountNumber: '0987654321',
    balance: 35000
  }
]);
