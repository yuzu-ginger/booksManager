def form   # New registration of books
  choice1 = "本を登録する"
  {
      "type": "template",
      "altText": "本登録フォーム",

      "template": {
          "type": "buttons",
          "title": "本の登録フォーム",
          "text": "タップしてください",

          "actions": [
              {
                  type: 'uri',
                  label: choice1,
                  uri: "https://liff.line.me/1657269514-NWB4YYMB/"
              }
          ]
      }
  }
end

def show_books     # View all books
  choice1 = "詳細"
  {
      "type": "template",
      "altText": "蔵書一覧",

      "template": {
          "type": "buttons",
          "title": "蔵書一覧",
          "text": "詳細はボタンをタップしてください",

          "actions": [
              {
                  type: 'uri',
                  label: choice1,
                  uri: "https://liff.line.me/1657269514-NWB4YYMB/A"
              }
          ]
      }
  }
end

def delete_book(title, book_id)  # Confirmation button to delete the book
  {
    "type": "template",
    "altText": "本の削除",
    "template": {
        "type": "confirm",
        "text": "#{title}を本当に削除しますか?",
        "actions": [
            {
                "type": "postback",
                "label": "はい",
                "data": "delete,#{book_id}",
                "displayText": "はい",
            },
            {
                "type": "postback",
                "label": "いいえ",
                "data": "nothing",
                "displayText": "いいえ",
            }
        ]
    }
  }
end