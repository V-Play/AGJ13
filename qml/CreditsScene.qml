import QtQuick 1.1
import VPlay 1.0

// is shown at game start and shows the maximum highscore and a button for starting the game
SceneBase {

  onBackPressed: {
    window.state = "main"
  }

  // this allows navigation through key presses
  Keys.onReturnPressed: {
    window.state = "main"
  }


  ParallaxScrollingBackground {
    x: scene.gameWindowAnchorItem.x
    sourceImage: "img/background-snow1-sd.png"
    sourceImage2: "img/background-snow2-sd.png"
    movementVelocity: Qt.point(-80,0)
  }

  Column {
    id: leftColumn
    anchors.verticalCenter: parent.verticalCenter
    x: 50
    y: 50
    spacing: 15

    MenuText {
      text: qsTr("V-Play Team:\nAlex Leutgoeb\nChristian Feldbacher\nDavid Berger\nNico Harather")
    }

    MenuText {
      text: qsTr("Graphics:\nMarkus Fellner")
    }
  }

  MenuButton {
    id: b1
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 30

    text: qsTr("Back")

    width: 170 * 0.8
    height: 60 * 0.8

    onClicked: window.state = "main"
  }

  Column {
    id: logoColumn
    //anchors.top: b1.top
    //anchors.topMargin: -8
    anchors.left: leftColumn.right
    anchors.leftMargin: 30
    anchors.verticalCenter: parent.verticalCenter
    spacing: 8

    MenuText {
      text: qsTr("Proudly developed with")
    }

    Image {
      source: "img/vplay.png"
      // the image size is bigger (for hd2 image), so only a single image no multiresimage can be used
      // this scene is not performance sensitive anyway!
      fillMode: Image.PreserveAspectFit
      height: 55

      MouseArea {
        anchors.fill: parent
        onClicked: nativeUtils.openUrl("http://v-play.net");
      }
    }
  }

}
