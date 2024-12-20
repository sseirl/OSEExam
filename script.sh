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
cp "$DB_CONFIG_FILE" "$PROJECT_DIR/settings.py"

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
