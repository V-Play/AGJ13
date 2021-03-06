
import QtQuick 1.1
import Box2D 1.0
import VPlay 1.0
import "entities"
import "particles"
import "scripts/levelLogic.js" as LevelLogic

Item {
  id: level

  // gets used to measure how much the level was moved downwards in the last frame - if this is bigger than gridSize, a new row will be created in onYChanged
  property real lastX: 0
  // for calculating the scores
  property real lastFrameX: 0

  // how many new rows were created, it starts with 0 if the level has y position 0, and then gets increased with every gridSize
  // gets initialized in onCompleted
  property real currentTrackColumn: 0

  // the player starts in the middle track 0, and then moves upwards or downwards
  property int playerRow: 1
  // the player track which is currently active which does not influent the startYForFirstRail.
  property int playerRowActive: 1

  property int railAmount: 3

  property real startYForFirstRail: level.height/2 - (railAmount-playerRow)/2 * trackSectionHeight

  // this is needed so an alias can be created from the main window!
  property alias player: player

  // specifies the px/second how much the level moves

  property real levelMovementSpeedMinimum: 20
  property real levelMovementSpeedMaximum: 400
  property real levelMovementSpeed: 50//levelMovementSpeedMinimum
  property alias levelMovementSpeedCurrent: levelMovementAnimation.velocity
  property alias splatterParticle: splatterParticle
  // gets modified, the higher the speed is from MovementAnimation - if it is 0, the speed is minimum, if it is 1, the speed is maximum
  property real speedScoringMultiplier: levelMovementSpeed-levelMovementSpeedMinimum / levelMovementSpeedMaximum

  // probability of 30% to create a obstacle on top of the track, so in 3 of 10 tracks there will be a obstacle created
  property real obstacleCreationPropability: 0.3
  // is needed internally to avoid creating too many windows close to each other
  property int lastWindowY: 0

  // the background images are moved up by this offset so on widescreen devices the full background is visible
  property real __yOffsetForWindow: scene.__yOffsetForAbsoluteWindowCoordinates

  // gets emitted when a BorderRegion.onPlayerCollision() is received
  signal gameLost

  property real trackSectionWidth: 118 // (120 is img size) //scene.width/7 // this must be the image size! make it at least 1 pixel smaller, so the images overlap a bit!
  property real trackSectionHeight: scene.height/5 // this is NOT the image size!

  // make some more, so they are created outside of the screen also at 16:9 devices
  // do not set too many in the future, because then there are not that many switches created at the current player rail
  property int numVisibleTracks: scene.gameWindowAnchorItem.width/trackSectionWidth + 2 // for testing the creation and make it visible in the scene, set the additional amount to 0

  // the background images are moved up by this offset so on widescreen devices the full background is visible
  property real __xOffsetForWindow: scene.__xOffsetForAbsoluteWindowCoordinates


  // players collide with obstacles (game lost) and trackSections (if direction chan
  // borderRegion collides with obstacles and trackSections
  property int borderRegionColliderGroup: Box.Category1
  property int trackSectionColliderGroup: Box.Category2
  property int playerColliderGroup: Box.Category3
  property int obstacleColliderGroup: Box.Category4

  // TODO: test if pooling is SLOWER than re-creation!?
  // pooling doesnt work with variationTypes yet!
  property bool trackSectionPoolingEnabled: true

  // multiplayer: 2nd player must scoop coal to increase pressure, single player: pressure increases by time
  property bool multiplayer: true

  // debug flags
  property bool showCollision: false
  property bool showTouchAreas: false

  // ------ probability values for balancing

  property real pSwitchAtPlayerRail: 0.4
  property real pSwitchAtNonPlayerRow: 0.2

  // Hhigher probability to create a cow, if there was a switch to the left.
  // Even higher, if the switch was where the player is.
  // On straight pieces, probability is low because player can only honk to escape the cows then.
  property real pCowAfterPlayerSwitchInLastColumn: 0.8
  property real pCowAfterNonPlayerSwitch: 0.4
  property real pCowFreePos: 0.02


//  EditableComponent {
//      id: editableEditorComponent
//      target: parent
//      type: "Level"
//      properties: {
//        /*
//"railAmount":               {"minimum": 0, "maximum": 10,"stepsize": 1,  "default": 3},
//        "playerRowActive":          {"minimum": 0, "maximum": railAmount,"stepsize": 1,  "default": 1},
//        "trackSectionPoolingEnabled":          {"minimum": false, "maximum": true, "default": trackSectionPoolingEnabled},
//        */

//        "pCowAfterPlayerSwitchInLastColumn": {"minimum": 0.01, "maximum": 1, "default": pCowAfterPlayerSwitchInLastColumn},
//        "pCowAfterNonPlayerSwitch": {"minimum": 0.01, "maximum": 1, "default": pCowAfterNonPlayerSwitch},
//        "pCowFreePos": {"minimum": 0.01, "maximum": 1, "default": pCowFreePos},

//        // Particle configuration properties
//        "obstacleCreationPropability":               {"minimum": 0, "maximum": 1, "default": 0.3,"stepsize": 0.01, "label": "Obstacles" /*,"group": "level"*/},
//        "levelMovementSpeed":                      {"minimum": 0, "maximum": 1000, "default": levelMovementSpeed,"stepsize": 1, /*"group": "level"*/},
//        "levelMovementSpeedMinimum":               {"minimum": 0, "maximum": 1000, "default": levelMovementSpeedMinimum,"stepsize": 1, /*"group": "level"*/},
//        "levelMovementSpeedMaximum":               {"minimum": 0, "maximum": 1000, "default": levelMovementSpeedMaximum,"stepsize": 1, /*"group": "level"*/},
//      }
//  }

  Component.onCompleted: {

    // this creates some roosts, coins and windows beforehand, so they dont need to be created at runtime
    preCreateEntityPool();

  }

  function preCreateEntityPool() {
    entityManager.createPooledEntitiesFromUrl(Qt.resolvedUrl("entities/TrackSection.qml"), 40);
    entityManager.createPooledEntitiesFromUrl(Qt.resolvedUrl("entities/Obstacle.qml"), 10);

  }


  function stopGame() {
    levelMovementAnimation.stop()

    // this function automatically pools all entities which have poolingEnabled set to true
    // and it ignores the entities that have preventFromRemovalFromEntityManager set to true
    entityManager.removeAllEntities();
    // from now on generate obstacles
    LevelLogic.generateObstacles = false
  }

  // initialize level data - this function can be called multiple times, so every time a new game gets started
  // it is called from ChickenOutbreakScene.enterScene()
  function startGame() {
    // it is important that lastY is set first, so the dy in onYChanged will be 0 and no new row is created
    currentTrackColumn = 0

    // it is important to set lastX before level.x! otherwise in onXChanged it would lead to a creation already!
    lastX = -0
    lastFrameX = 0
    level.x = lastX

    player.init()

    levelMovementSpeedCurrent = levelMovementSpeed

    LevelLogic.init()
    for(var i=0; i<numVisibleTracks; i++) {
      LevelLogic.createRandomRowForRowNumber(i);
    }
    // from now on generate obstacles
    LevelLogic.generateObstacles = true


    levelMovementAnimation.start();

  }

  // this is the offset of the 2 backgrounds
  // make the offset a litte bit smaller, so no black background shines through when they are put below each other
  property real levelBackgroundWidth: levelBackground.width*levelBackground.scale-1

  // handles the repositioning of the background, if they are getting out of the scene
  // internally, 4 images are created below each other so it appears to the user as being one continuous background
  ParallaxScrollingBackground {
    id: levelBackground

    x: -level.x
    sourceImage: "img/background-snow1-sd.png"
    sourceImage2: "img/background-snow2-sd.png"
    movementVelocity: Qt.point(levelMovementAnimation.velocity,0)
    running: levelMovementAnimation.running // start non-running, gets set to true in startGame
  }

  SplatterParticle {
    id: splatterParticle
    z: 2
  }

  // start in the center of the scene, and a little bit below the top
  // the player will fall to the playerInitialBlock below at start
  Player {
    id: player

    x: -level.x + player.sprite.width/2
    // y will be initialized in init()

    // this guarantees the player is in front of the henhouseWindows
    z: 1
    onDied: {
      console.debug("PLAYER COLLIDED WITH obstacle, level.y:", level.y, ", player.y:", player.y)
      // emit the gameLost signal, which is handled in MainScene
      gameLost();
    }
    onCollisionWithTrackSection: {
      //console.debug("PLAYER COLLIDED WITH trackelement, variation:",direction)
      if(direction === "up") {
        playerRowActive--
        if(playerRowActive<0)
          playerRowActive = 0
      } else if(direction === "down") {
        playerRowActive++
        if(playerRowActive>railAmount-1)
          playerRowActive = railAmount-1
      }
      player.trackChangeTo(Qt.point(player.x+200,startYForFirstRail+(playerRowActive)*trackSectionHeight))
    }

    SmokeParticle {
      id: chimneyParticle
      x: 30
      Component.onCompleted: {
        chimneyParticle.start()
      }
    }
    SmokeParticle {
      id: chimneyExplotionParticle
      x: 30
      sourcePositionVariance: Qt.point(7,7)
      duration: 0.1
      gravity: Qt.point(0,0)
      particleLifespan: 0.46
      particleLifespanVariance: 0.11
      angleVariance: 360
      radialAcceleration: -1000
      tangentialAcceleration: 4
      finishParticleSize: 0
      finishParticleSizeVariance: 0
      speed: 200
      speedVariance: 6.58
      startColor: Qt.rgba(0.0,0.18,0.2,0.90)
      finishColor: Qt.rgba(1.0,1.0,1.0,0.0)
    }
  }

  BorderRegion {
    x: -level.x - width - trackSectionWidth*3
    height: scene.height// make bigger than the window, because the roost can stand out of the scene on the right side when the gridSize is not a multiple of the scene.width (which it currently is: 320/48=6.6) and thus if the player would stand on the right side no collision would be detected!
    width: 80 // make big enough, so they dont go through
  }

  Timer {
    id: pressureTimer

    // Trigger every 0.5 sec, so the maximum steam power of 100 would be lost after 5sec on full acceleration
    interval: 500;
    // Can't use levelMovementSpeed cause it never gets adapt to acceleration influenced velocity changes
    // Instead we use -levelMovementAnimation.velocity directly
    running: levelMovementAnimation.acceleration < 0 && player.steamPressure > 0 && -levelMovementAnimation.velocity !== levelMovementSpeedMaximum || levelMovementAnimation.acceleration > 0 && -levelMovementAnimation.velocity !== levelMovementSpeedMinimum
    repeat: true
    onTriggered: {
      // Acceleration is negative
      player.steamPressure += levelMovementAnimation.acceleration / 10

      if (player.steamPressure < 0) {
        player.steamPressure = 0
        // Stop acceleration if there is not enough pressure available
        levelMovementAnimation.acceleration = 0
      }
      else if (player.steamPressure > 200) {
        player.steamPressure = 200
      }
    }
  }

  Timer {
    id: pressureRegenerationTimer

    interval: 2500;
    // Only used in single player mode
    running: !multiplayer && levelMovementAnimation.running && !pressureTimer.running && player.steamPressure <= 100
    repeat: true
    onTriggered: {
      // Our steam pressure regenerates slowly while travelling uniformly
      player.steamPressure += 2
      if (player.steamPressure > 100) {
        player.steamPressure = 100
      }
    }
  }

  MovementAnimation {
    id: levelMovementAnimation
    property: "x"

    target: level
    // target: tracks probably wont work, because physics only takes the direct position!?

    // this is the movement in px per second, start with very slow movement, 10 px per second
    velocity: -levelMovementSpeed

    onVelocityChanged: {
      player.velocity = velocity
      scene.snowing.gravity.x = velocity
      var colormult = velocity*(-1)/400
      if(colormult>0.80) {
        chimneyExplotionParticle.start()
        chimneyParticle.startColor = Qt.rgba(0.0,0.18,0.2,0.9)
      } else {
        chimneyParticle.startColor = Qt.rgba(1-colormult,1-colormult,1-colormult,colormult)
      }
      //console.debug("vel changed to:", velocity)


      // the faster the player moves, the more points he gets
      speedScoringMultiplier = (-velocity-levelMovementSpeedMinimum)/levelMovementSpeedMaximum
    }

    // running is set to false - call start() here
    // increase the velocity by this amount of pixels per second, so it lasts minVelocity/acceleration seconds until the maximum is reached!
    // i.e. -70/-2 = 45 seconds
    //90-20 = 70 / 30 = 2.5
    acceleration: 0 //-(levelMovementSpeedMaximum-levelMovementSpeedMinimum) / levelMovementDurationTillMaximum

    // limit the maximum v to 100 px per second - it must not be faster than the gravity! this is the absolute maximum, so the chicken falls almost as fast as the background moves by! so rather set it to -90, or increase the gravity
    minVelocity: -levelMovementSpeedMaximum
    // Use a certain minimum speed
    maxVelocity: -levelMovementSpeedMinimum
  }

  onXChanged: {
    // y gets more and more negative, so e.g. -40 - (-25) = -15
    var dx = x - lastX;
    //console.debug("level.dx:", -dx, "currentRow:", currentRow, ", x:", -x, ", lastX:", -lastX)
    if(-dx > trackSectionWidth) {

      // 4.7.toFixed() will lead to a value of 4
      // dont use ceil() here
      var amountNewRows = (-dx/trackSectionWidth).toFixed();
      //console.debug(amountNewRows, "new rows are getting created...")

      if(amountNewRows>1) {
        console.debug("WARNING: the step difference was too big, more than 1 track got created!")
      }

      // if y changes a lot within the last frame, multiple rows might get created
      // this doesnt happen with fixed dt, but it could happen with varying dt where more than 1 row might need to be created because of such a big y delta
      for(var i=0; i<amountNewRows; i++) {        
        // this guarantees it is created outside of the visual screen
        LevelLogic.createRandomRowForRowNumber(currentTrackColumn+numVisibleTracks);
        currentTrackColumn++;
        // it's important to decrease lastX like that, not setting it to x!
        lastX -= trackSectionWidth
      }

      // this would be wrong! the dx will be a little bit higher, so lastX would be wrong
      //lastX = x;

    }
    player.score = -(level.x/40).toFixed()

    if(!player.followingPath) {
      player.x = -level.x + player.sprite.width/2
    }

    lastFrameX = level.x

  }

  function accelerate(diff) {
    levelMovementAnimation.acceleration += diff
  }

  function setAcceleration(acceleration) {
    // do not acc when on path
    if(!player.followingPath)
    {
      // We can't accelerate if our steam pressure is 0
      if (player.steamPressure <= 0 && acceleration < 0)
        return;

      levelMovementAnimation.acceleration = acceleration * 10

    }
  }

  function moveFirstObstacleInCurrentTrack() {
    // Get obstacles of type cow
    var obstacles = entityManager.getEntityArrayByType("obstacle")

    var currentY = startYForFirstRail + playerRowActive * trackSectionHeight

    for (var i = 0; i < obstacles.length; i++) {
      var o = obstacles[i]

      // Use obstacle only if on current track and before the player
      if (o.y === currentY && o.x > player.x) {
        // Obstacle is on top
        if (playerRowActive == 0)
          o.y += trackSectionHeight
        // Obstacle is on bottom
        else if (playerRowActive === railAmount - 1)
          o.y -= trackSectionHeight
        // Obstacle is in between
        else {
          // Dirty random boolean
          //var flag = !! Math.round(Math.random() * 1)
          o.jump()
//          if (!o.directionUp) {
//            o.jump(false) // jump down
//            //o.y += trackSectionHeight
//          } else {
//            o.jump(true) // jump up
//            //o.y -= trackSectionHeight
//          }
        }
        return;
      }
    }
  }


  // ------------------- for debugging only ------------------- //
  function pauseGame() {
    levelMovementAnimation.stop()
  }
  function resumeGame() {
    levelMovementAnimation.start()
  }

  function restartGame() {
    stopGame();
    startGame();
  }
}
