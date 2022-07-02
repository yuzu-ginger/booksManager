def form(id)
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
                  uri: "https://liff.line.me/1657269514-NWB4YYMB/#{id}"  # 必須
              }
          ]
      }
  }
end

def show_books(id)
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
                  uri: "https://liff.line.me/1657269514-NWB4YYMB/index/#{id}"  # 必須
              }
          ]
      }
  }
end