const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

let monthlyBudget = 25000;
const categories = {
  expense: [
    'Еда',
    'Транспорт',
    'Учёба',
    'Дом',
    'Здоровье',
    'Развлечения',
    'Прочее'
  ],
  income: ['Зарплата', 'Стипендия', 'Подработка', 'Подарок', 'Прочее']
};
let transactions = [
  { id: '1', title: 'Обед в столовой университета', amount: 320, category: 'Еда', type: 'expense', comment: '', date: '13.11.2026' },
  { id: '2', title: 'Проездной / маршрутка', amount: 150, category: 'Транспорт', type: 'expense', comment: '', date: '13.11.2026' },
  { id: '3', title: 'Книга по архитектуре ПО', amount: 1450, category: 'Учёба', type: 'expense', comment: '', date: '12.11.2026' },
  { id: '4', title: 'Кофе и перекус', amount: 280, category: 'Еда', type: 'expense', comment: '', date: '11.11.2026' },
  { id: '5', title: 'Стипендия', amount: 5000, category: 'Стипендия', type: 'income', comment: '', date: '10.11.2026' }
];

const validTypes = ['expense', 'income'];

app.get('/api/categories', (_req, res) => {
  res.json(categories);
});

app.post('/api/categories', (req, res) => {
  const { type, name } = req.body;
  if (!validTypes.includes(type) || typeof name !== 'string' ||
      !name.trim() || name.trim().length > 30) {
    return res.status(400).json({ error: 'Укажите тип и название до 30 символов' });
  }

  const normalizedName = name.trim();
  if (categories[type].some(
    category => category.toLocaleLowerCase('ru') === normalizedName.toLocaleLowerCase('ru')
  )) {
    return res.status(409).json({ error: 'Такая категория уже существует' });
  }

  categories[type].push(normalizedName);
  res.status(201).json({ type, name: normalizedName });
});

function isValidTransaction(type, title, amount, category) {
  return validTypes.includes(type) &&
    typeof title === 'string' && title.trim().length > 0 &&
    Number.isFinite(Number(amount)) && Number(amount) > 0 &&
    typeof category === 'string' && category.trim().length > 0;
}

function isValidDate(value) {
  if (value === undefined) return true;
  if (typeof value !== 'string' || !/^\d{2}\.\d{2}\.\d{4}$/.test(value)) {
    return false;
  }
  const [day, month, year] = value.split('.').map(Number);
  const date = new Date(year, month - 1, day);
  return date.getFullYear() === year &&
    date.getMonth() === month - 1 &&
    date.getDate() === day;
}

function createTransaction({ type, title, amount, category, comment = '', date }) {
  return {
    id: Date.now().toString(),
    title: title.trim(),
    amount: Number(amount),
    category: category.trim(),
    type,
    comment: typeof comment === 'string' ? comment.trim() : '',
    date: date || new Date().toLocaleDateString('ru-RU')
  };
}

app.get('/api/transactions', (req, res) => {
  const type = req.query.type;
  const items = validTypes.includes(type)
    ? transactions.filter(item => item.type === type)
    : transactions;

  res.json({
    totalExpenses: transactions
      .filter(item => item.type === 'expense')
      .reduce((sum, item) => sum + item.amount, 0),
    totalIncome: transactions
      .filter(item => item.type === 'income')
      .reduce((sum, item) => sum + item.amount, 0),
    items
  });
});

app.post('/api/transactions', (req, res) => {
  const { type, title, amount, category, comment, date } = req.body;
  if (!isValidTransaction(type, title, amount, category) || !isValidDate(date)) {
    return res.status(400).json({ error: 'Проверьте тип, название, категорию и сумму' });
  }

  const transaction = createTransaction({
    type,
    title,
    amount,
    category,
    comment,
    date
  });
  transactions.unshift(transaction);
  res.status(201).json(transaction);
});

app.patch('/api/transactions/:id', (req, res) => {
  const transaction = transactions.find(item => item.id === req.params.id);
  if (!transaction) {
    return res.status(404).json({ error: 'Запись не найдена' });
  }

  const updated = {
    ...transaction,
    ...req.body,
    id: transaction.id,
    date: transaction.date
  };
  if (!isValidTransaction(updated.type, updated.title, updated.amount, updated.category)) {
    return res.status(400).json({ error: 'Проверьте тип, название, категорию и сумму' });
  }
  updated.title = updated.title.trim();
  updated.amount = Number(updated.amount);
  updated.category = updated.category.trim();
  updated.comment = typeof updated.comment === 'string' ? updated.comment.trim() : '';

  transactions = transactions.map(item => item.id === updated.id ? updated : item);
  res.json(updated);
});

app.delete('/api/transactions/:id', (req, res) => {
  const before = transactions.length;
  transactions = transactions.filter(item => item.id !== req.params.id);
  if (transactions.length === before) {
    return res.status(404).json({ error: 'Запись не найдена' });
  }
  res.status(204).send();
});

app.get('/api/expenses', (req, res) => {
  const expenses = transactions.filter(item => item.type === 'expense');
  const category = req.query.category || 'Все';
  const items = category === 'Все'
    ? expenses
    : expenses.filter(item => item.category === category);

  const totalSpent = expenses.reduce((sum, item) => sum + item.amount, 0);
  res.json({
    budget: monthlyBudget,
    totalSpent,
    remaining: monthlyBudget - totalSpent,
    items
  });
});

app.post('/api/expenses', (req, res) => {
  const { title, amount, category } = req.body;
  if (!isValidTransaction('expense', title, amount, category || 'Прочее')) {
    return res.status(400).json({ error: 'Укажите название и положительную сумму' });
  }

  const transaction = createTransaction({
    type: 'expense',
    title,
    amount,
    category: category || 'Прочее'
  });
  transactions.unshift(transaction);
  res.status(201).json(transaction);
});

app.delete('/api/expenses/:id', (req, res) => {
  const before = transactions.length;
  transactions = transactions.filter(item =>
    item.id !== req.params.id || item.type !== 'expense'
  );
  if (transactions.length === before) {
    return res.status(404).json({ error: 'Расход не найден' });
  }
  res.status(204).send();
});

app.get('/api/health', (_req, res) => res.json({ status: 'ok' }));

const webBuildPath = path.resolve(__dirname, '..', 'mobile_app', 'build', 'web');
app.use(express.static(webBuildPath));
app.get('*', (req, res, next) => {
  if (req.path.startsWith('/api/')) return next();
  res.sendFile(path.join(webBuildPath, 'index.html'), error => {
    if (error) next(error);
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`SomTracker API running on http://localhost:${PORT}`);
});
