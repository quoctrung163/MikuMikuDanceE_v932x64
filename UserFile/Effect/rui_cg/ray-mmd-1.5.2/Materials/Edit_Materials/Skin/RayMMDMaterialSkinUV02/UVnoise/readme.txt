UVnoise	V01	by non0

これは、PMXエディター用プラグインです。
PMXエディタでUV展開された個々の座標にノイズを追加する事が出来ます。

これ水滴が流れるように見えるように水滴が規則性なく揺れているように見せる為に
作成しています。。。他に使いみちがあるのかなぁ？

動作確認は、以下で行っています。
PMXエディタ　0.2.5.4  x64 bit
*x32 bitも動作すると思いますが、チェック環境がない為未実施

・他にないと苦労しそうなプラグイン。
　どるる式UVエディタ　https://bowlroll.net/file/15244
　UVの状態がどのようになっているか目視＆変更出来ます。

＜使い方＞
・本プラグイン（UVnoise)を実行して下さい。
・PMXViewでUVにノイズを加えたいと思っている頂点を選択して下さい。
・UVnoiseにある”選択”をクリック。これで選択された頂点数が出ます。
・加えるノイズを指定して下さい。X,Y（U,V)個別に設定出来ます。
　ここで加えるノイズは少し少なめから初めて下さい。（モデルによりUVの細かさが
　違うので一概にはいえませんが、0.002-0.01とかかな？　）
　どるる式UVエディタ等でどのようにノイズが乗っているのか確認するとやりやすいかも
　（ノイズを加えて、本体からモデル受信とすれば、ノイズ？ぶれが確認出来ます）
　ちなみに水が下に流れるようなノイズ（ぶれ）は、X（U）<Y（V）がいいように
　思いますが、好みでいろいろやって見て下さい。
　（ハイフェンさん（改造）では　X,Y = 0.003,0.006 を採用してみています。
　　参考　変更前：original.png 　ノイズ後:mod.png
     このモデルは左右鏡像でUV値が元は左右で重なっていますが、ノイズ後はずれてます。)
　　　
-----------------------------------------------------------------------------------
履歴）
	2019.12.30	ｖ01　初版


