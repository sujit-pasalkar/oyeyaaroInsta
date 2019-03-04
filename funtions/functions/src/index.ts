import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
admin.initializeApp();

//private chat
exports.newSubscriberNotification = functions.firestore
  .document('Private/{idTo}/{idTo1}/{timestamp}')
  .onCreate(async event => {

    const data = event.data();
    const receiverId = data.receiverPin;
    const title = data.senderName;
    const msg = data.msg;

    // Notification content
    const payload = {
      notification: {
        title: 'Message from: ' + title,//data.title
        body: msg,//data.body
        icon: 'https://goo.gl/Fz9nrQ',
        badge: '1',
        sound: 'default'
      }
    }

    // ref to the device collection for the user
    const db = admin.firestore()
    const devicesRef = db.collection('userTokens').where('id', '==', receiverId)

    // get the user's tokens and send notifications
    const devices = await devicesRef.get();

    const tokens = [];
    // send a notification to each device token
    devices.forEach(result => {
      const token = result.data().token;

      tokens.push(token)
    })

    return admin.messaging().sendToDevice(tokens, payload)

  });

//group chat 
exports.groupChatNotification = functions.firestore
  .document('groups/{idTo}/{idTo1}/{timestamp}')
  .onCreate(async event => {
    const data = event.data();
    // console.log('data : '+data.members)
    const receiverId = data.members;
    const payload = {
      notification: {
        title: data.groupName+' : ' + data.senderName,//data.title
        body: data.msg,//data.body
        icon: 'https://goo.gl/Fz9nrQ',
        badge: '1',
        sound: 'default'
      }
    }

    receiverId.forEach((rec)=>{
      notify(payload, rec).then(()=>{
        console.log("sent to "+rec);
      }).catch((error)=>{
        console.error(error);
      });
    });
    return true;
  });


  async function notify(payload,receiverId){
    // ref to the device collection for the user
    const db = admin.firestore()
    const devicesRef = db.collection('userTokens').where('id', '==', receiverId)

    // get the user's tokens and send notifications
    const devices = await devicesRef.get();
    const tokens = [];

    // send a notification to each device token
    devices.forEach(result => {
      const token = result.data().token;

      tokens.push(token)
    })

    return admin.messaging().sendToDevice(tokens, payload)
  }