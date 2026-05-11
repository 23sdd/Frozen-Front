#!/bin/bash


echo "Имя лидера (локализация): "
read char_name
echo "ID (например, NAS_William): "
read char_id
echo "TAG (например, NAS): "
read tag
echo "Идеология (например, democratic_subideology): "
read ideology
echo "Путь к исходному фото (перетащи файл): "
read img_path


img_path=$(echo "$img_path" | tr -d "'\""  | xargs)


if [ ! -f "$img_path" ]; then
    echo "Ошибка: файл '$img_path' не найден."
    exit 1
fi


if ! command -v convert &> /dev/null; then
    echo "Ошибка: ImageMagick не установлен. Установи через: brew install imagemagick"
    exit 1
fi


MOD_PATH="."

GFX_DIR="$MOD_PATH/gfx/leaders/$tag"
CHAR_DIR="$MOD_PATH/common/characters"
CHAR_FILE="$CHAR_DIR/${tag}.txt"
GFX_INTERFACE_FILE="$MOD_PATH/interface/aat_traits.gfx"

mkdir -p "$GFX_DIR" "$CHAR_DIR" "$MOD_PATH/interface"


img_filename="Portraite_${char_id}.dds"
dest_img="$GFX_DIR/${img_filename}"

echo "Конвертация в DDS (156x210)..."
convert "$img_path" \
    -resize 156x210! \
    -define dds:compression=dxt5 \
    "$dest_img"

if [ $? -ne 0 ]; then
    echo "Ошибка: не удалось конвертировать фото."
    exit 1
fi
echo "Фото конвертировано и сохранено: $dest_img"


if [ ! -f "$CHAR_FILE" ]; then
    echo "characters = {" > "$CHAR_FILE"
    echo "}" >> "$CHAR_FILE"
fi

if grep -q "${char_id}" "$CHAR_FILE"; then
    echo "Предупреждение: персонаж с ID '${char_id}' уже есть в файле. Пропускаем запись."
else
    cat <<EOF > new_char.tmp
	${char_id} = {
		name = "${char_name}"
		portraits = {
			civilian = {
				large = GFX_portrait_${char_id}
			}
		}
		country_leader = {
			ideology = ${ideology}
			expire = "1950.1.1.1"
			id = -1
		}
	}
EOF

    grep -v "^}" "$CHAR_FILE" > "$CHAR_FILE.new"
    cat new_char.tmp >> "$CHAR_FILE.new"
    echo "}" >> "$CHAR_FILE.new"
    mv "$CHAR_FILE.new" "$CHAR_FILE"
    rm new_char.tmp
    echo "Персонаж добавлен: $CHAR_FILE"
fi


if [ ! -f "$GFX_INTERFACE_FILE" ]; then
    echo "spriteTypes = {" > "$GFX_INTERFACE_FILE"
    echo "}" >> "$GFX_INTERFACE_FILE"
fi

if grep -q "GFX_portrait_${char_id}" "$GFX_INTERFACE_FILE"; then
    echo "Предупреждение: спрайт 'GFX_portrait_${char_id}' уже есть в .gfx файле. Пропускаем."
else
    cat <<EOF > new_gfx.tmp
	spriteType = {
		name = "GFX_portrait_${char_id}"
		texturefile = "gfx/leaders/${tag}/${img_filename}"
	}
EOF

    grep -v "^}" "$GFX_INTERFACE_FILE" > "$GFX_INTERFACE_FILE.new"
    cat new_gfx.tmp >> "$GFX_INTERFACE_FILE.new"
    echo "}" >> "$GFX_INTERFACE_FILE.new"
    mv "$GFX_INTERFACE_FILE.new" "$GFX_INTERFACE_FILE"
    rm new_gfx.tmp
    echo "Спрайт добавлен: $GFX_INTERFACE_FILE"
fi


echo ""
echo "Готово! Лидер '${char_name}' (${char_id}) создан."
echo "  Фото:      $dest_img"
echo "  Персонаж:  $CHAR_FILE"
echo "  Интерфейс: $GFX_INTERFACE_FILE"