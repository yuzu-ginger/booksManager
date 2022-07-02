def form
  choice1 = "本を登録する"
  {
      "type": "template",
      "altText": "本登録フォーム",

      "template": {
          "type": "buttons",
          "title": "本の登録フォーム",
          "text": "タップしてください",

          # ポストバックアクション
          "actions": [
              {
                  type: 'uri',
                  label: choice1,   # 必須または任意
                  uri: "https://liff.line.me/1657269514-NWB4YYMB/"  # 必須
              }
          ]
      }
  }
end

def show_books
  choice1 = "詳細"
  {
      "type": "template",
      "altText": "蔵書一覧",

      "template": {
          "type": "buttons",
          "title": "蔵書一覧",
          "text": "詳細はボタンをタップしてください",

          # ポストバックアクション
          "actions": [
              {
                  type: 'uri',
                  label: choice1,   # 必須または任意
                  uri: "https://liff.line.me/1657269514-NWB4YYMB/A"  # 必須
              }
          ]
      }
  }
end

def delete_book(title, book_id)
  {
    "type": "template",    # 必須
    "altText": "本の削除",   # 必須
    "template": {          # 必須
        "type": "confirm",         # 必須
        "text": "#{title}を本当に削除しますか?",   # 必須
        "actions": [               # 必須
            {
                "type": "postback",
                "label": "はい",
                "data": "delete,#{book_id}",
                "displayText": "はい",
            },
            {
                "type": "postback",
                "label": "はい",
                "data": "nothing",
                "displayText": "いいえ",
            }
        ]
    }
  }
end