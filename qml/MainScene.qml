// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import VPlay 1.0

// is shown at game start and shows the maximum highscore and a button for starting the game
SceneBase {
  id: mainScene

  Connections {
    // nativeUtils should only be connected, when this is the active scene
      target: activeScene === mainScene ? nativeUtils : null
      onMessageBoxFinished: {
        if(accepted)
          Qt.quit()
      }
  }

  onBackPressed: {
    nativeUtils.displayMessageBox(qsTr("Really quit the game?"), "", 2);
  }

  ParallaxScrollingBackground {
    id: levelBackground

    x: scene.gameWindowAnchorItem.x
    sourceImage: "img/background-snow1-sd.png"
    sourceImage2: "img/background-snow2-sd.png"
    movementVelocity: Qt.point(-80,0)
  }

  Column {
    spacing: 5
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    MenuText {
      text: "Locomotive Breath"
      font.pixelSize: 35
      //font.bold: true
    }

    MenuText {
      text: "Highscore: " + maximumHighscore
    }

    MenuButton {
      text: "Play"
      onClicked: window.state = "game"
      textSize: 30
    }

    MenuButton {
      text: window.level.multiplayer ?  "2 Players" : "1 Player"

      width: 170 * 0.8
      height: 60 * 0.8

      onClicked: window.level.multiplayer = !window.level.multiplayer;
    }


    MenuButton {
      text: "Credits"

      width: 170 * 0.8
      height: 60 * 0.8

      onClicked: window.state = "credits";
    }

    MenuButton {
      text: settings.soundEnabled ? "Sound on" : "Sound off"

      width: 170 * 0.8
      height: 60 * 0.8

      onClicked: settings.soundEnabled = !settings.soundEnabled


      // this button should only be displayed on Symbian & Meego, because on the other platforms the volume hardware keys work; but on Sym & Meego the volume cant be adjusted as the hardware volume keys are not working
      // also, display it when in debug build for quick toggling the sound
      visible: system.debugBuild || system.isPlatform(System.Meego) || system.isPlatform(System.Symbian)
    }
  }

  // this allows navigation through key presses
  Keys.onReturnPressed: {
    window.state = "game"
  }
}
