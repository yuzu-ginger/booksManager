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
                  uri: "https://liff.line.me/1657269514-JYwpqqmw/#{id}"  # 必須
              }
          ]
      }
  }
end
