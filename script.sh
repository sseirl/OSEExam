#!/bin/bash

sudo apt update
sudo apt install -y python3-pip python3-dev libpq-dev nginx

# Указываем путь к директории с проектом
PROJECT_DIR="$1"

# Указываем директорию для виртуального окружения
VENV_DIR="$2"

# Указываем путь к репозиторию Git
GIT_REPO="$3"

# Указываем путь к файлу настроек базы данных (можно использовать .env или settings.py)
DB_CONFIG_FILE="$4"

# Указываем директорию для статичных файлов
STATIC_DIR="$5"

# Проверяем, переданы ли все необходимые аргументы
if [ -z "$PROJECT_DIR" ] || [ -z "$VENV_DIR" ] || [ -z "$GIT_REPO" ] || [ -z "$DB_CONFIG_FILE" ] || [ -z "$STATIC_DIR" ]; then
  echo "Использование: $0 <путь к директории с проектом> <путь к виртуальному окружению> <путь к репозиторию> <путь к файлу конфигурации базы данных> <путь к директории для статичных файлов>"
  exit 1
fi

# Проверяем, существует ли директория проекта
if [ ! -d "$PROJECT_DIR" ]; then
  echo "Ошибка: директория проекта $PROJECT_DIR не существует!"
  exit 1
fi

# Проверяем, существует ли репозиторий Git
if [ ! -d "$PROJECT_DIR/.git" ]; then
  echo "Клонируем репозиторий из Git..."
  git clone "$GIT_REPO" "$PROJECT_DIR"
fi


# Создаем виртуальное окружение, если оно не существует
if [ ! -d "$VENV_DIR" ]; then
  echo "Создаем виртуальное окружение..."
  python3 -m venv "$VENV_DIR"
fi

# Активируем виртуальное окружение
source "$VENV_DIR/bin/activate"

# Устанавливаем зависимости из requirements.txt
echo "Устанавливаем зависимости..."
pip install -r "$PROJECT_DIR/requirements.txt"

# Настройка базы данных (например, копирование конфигурации)
echo "Настроим базу данных..."
cp "$DB_CONFIG_FILE" "$PROJECT_DIR/testPrj/settings.py"

# Применяем миграции
echo "Применяем миграции базы данных..."
python "$PROJECT_DIR/manage.py" migrate

# Сбор статичных файлов
echo "Собираем статичные файлы..."
python "$PROJECT_DIR/manage.py" collectstatic --noinput

# Настройка Gunicorn для работы с проектом (если необходимо)
echo "Настроим Gunicorn..."
gunicorn --workers 3 testPrj.wsgi:application &

# Настройка и перезапуск Nginx (если настроен)
echo "Настроим Nginx..."
sudo cp "$PROJECT_DIR/nginx_config" /etc/nginx/sites-available/project
sudo ln -s /etc/nginx/sites-available/project /etc/nginx/sites-enabled/
sudo systemctl restart nginx

# Выводим сообщение об успешном развертывании
echo "Проект успешно развернут и работает!"

# Ожидаем, что пользователь завершит работу скрипта
wait


