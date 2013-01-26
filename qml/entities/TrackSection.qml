import QtQuick 1.1
import VPlay 1.0

EntityBase {
  entityType: "trackSection"
  // there are 4 variationTypes: straight, up, down, and both directions
  // depending on which direction the switch has, the player will be moved to that direction
  property string variationTypes: "straight"
  // there are 3 variationSource: sender, receiver, none (straight)
  property string variationSource: "none"

  // this is important - a lot get removed and destroyed dynamically!
  poolingEnabled: true


  Rectangle {
    id: img
    width: scene.width/7
    height: scene.height/5
    anchors.centerIn: parent
    color: "grey"

    Rectangle {
      id: main
      width: parent.width
      height:  parent.height*0.5
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 1
      anchors.rightMargin: 1
      color: "brown"
    }
    Rectangle {
      x: variationSource === "sender" ? 0 : main.width-height
      anchors.bottom: main.top
      width: 5
      height: 5
      color: variationSource === "sender" ? "green" : variationSource === "receiver" ? "red" : "white"
      visible: variationTypes === "up" || variationTypes === "both"
    }
    Rectangle {
      x: variationSource === "sender" ? 0 : main.width-height
      anchors.top: main.bottom
      width: 5
      height: 5
      color: variationSource === "sender" ? "green" : variationSource === "receiver" ? "red" : "white"
      visible: variationTypes === "down" || variationTypes === "both"
    }
  }

  BoxCollider {
    anchors.fill: img
    collisionTestingOnlyMode: true
    sensor: true
  }

}
