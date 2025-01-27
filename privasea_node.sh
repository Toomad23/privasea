#!/bin/bash

# Функция для установки ноды
install_node() {
    echo "Обновление пакетов и установка Docker..."
    sudo apt update && sudo apt upgrade -y

    echo "Добавление ключа Docker и настройка репозитория..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    docker version

    echo "Установка Docker Compose..."
    VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

    chmod +x /usr/local/bin/docker-compose
    docker-compose --version

    echo "Загрузка образа Privasea Node..."
    docker pull privasea/acceleration-node-beta:latest

    echo "Создание директории для конфигурации..."
    mkdir -p ~/privasea/config && cd ~/privasea

    echo "Создание нового кошелька..."
    docker run --rm -it -v "$HOME/privasea/config:/app/config" privasea/acceleration-node-beta:latest ./node-calc new_keystore

    echo "Введите пароль для кошелька:"
    read -s PASSWORD

    echo "Сохранение информации о кошельке..."
    mv $HOME/privasea/config/UTC--* $HOME/privasea/config/wallet_keystore

    echo "Кошелек сохранен в: $HOME/privasea/config/wallet_keystore"
    echo "Добавьте этот файл в Metamask через импорт JSON."

    echo "Перейдите на https://deepsea-beta.privasea.ai/, подключите кошелек и получите faucet."
    echo "Нажмите 'Set up my node', введите имя ноды и адрес кошелька, установите комиссию на 1% и подтвердите."

    echo "Запуск ноды..."
    docker run -d --name privanetix-node -v "$HOME/privasea/config:/app/config" -e KEYSTORE_PASSWORD=$PASSWORD privasea/acceleration-node-beta:latest

    echo "Нода успешно установлена и запущена."
}

# Функция для просмотра логов
view_logs() {
    echo "Просмотр логов ноды..."
    docker logs --follow privanetix-node
}

# Функция для удаления ноды
remove_node() {
    echo "Остановка и удаление ноды..."
    docker stop privanetix-node
    docker rm privanetix-node
    echo "Нода успешно удалена."
}

# Функция для обновления ноды
update_node() {
    echo "Остановка текущей ноды..."
    docker stop privanetix-node
    docker rm privanetix-node

    echo "Загрузка последней версии образа Privasea Node..."
    docker pull privasea/acceleration-node-beta:latest

    echo "Запуск обновленной ноды..."
    docker run -d --name privanetix-node -v "$HOME/privasea/config:/app/config" -e KEYSTORE_PASSWORD=$PASSWORD privasea/acceleration-node-beta:latest

    echo "Нода успешно обновлена."
}

# Основное меню
while true; do
    echo "1. Установка ноды"
    echo "2. Просмотр логов"
    echo "3. Удаление ноды"
    echo "4. Обновление ноды"
    echo "5. Выход"
    read -p "Выберите опцию: " OPTION

    case $OPTION in
        1)
            install_node
            ;;
        2)
            view_logs
            ;;
        3)
            remove_node
            ;;
        4)
            update_node
            ;;
        5)
            echo "Выход..."
            exit 0
            ;;
        *)
            echo "Неверный выбор. Попробуйте снова."
            ;;
    esac
done
