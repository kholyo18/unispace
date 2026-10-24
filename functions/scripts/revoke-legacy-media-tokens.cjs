'use strict';
const args=process.argv.slice(2),apply=args.includes('--apply');
const value=key=>{const i=args.indexOf(key);return i<0?undefined:args[i+1];};
const project=value('--project');
if(project!=='fachub-c631c')throw Error('Pass the exact UniSpace project with --project fachub-c631c');
if(process.env.FIRESTORE_EMULATOR_HOST||process.env.FIREBASE_STORAGE_EMULATOR_HOST)throw Error('Use injected unit tests for emulators; this operator tool is project-specific');
const {initializeApp}=require('firebase-admin/app');
const {getFirestore}=require('firebase-admin/firestore');
const {getStorage}=require('firebase-admin/storage');
const {createLegacyMediaTokenMigration}=require('../security/legacy-media-token-migration');
const app=initializeApp({projectId:project});
const bucket=value('--bucket');
if(![project+'.appspot.com',project+'.firebasestorage.app'].includes(bucket))throw Error('Pass the verified application --bucket explicitly');
createLegacyMediaTokenMigration({db:getFirestore(app),bucket:()=>getStorage(app).bucket(bucket)})({apply,
  verifiedBuild:Number(value('--verified-build')),maximumPages:10})
 .then(result=>process.stdout.write(JSON.stringify(result)+'\n')).catch(error=>{process.stderr.write(error.message+'\n');process.exitCode=1;});