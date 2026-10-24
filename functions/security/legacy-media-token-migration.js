'use strict';
// Deliberate cutover tool: never run before both the client and deny-write rules
// have been verified. Revocation changes capabilities, not stored locators/bytes.
function createLegacyMediaTokenMigration({db,bucket,now=Date.now}) {
  return async ({apply=false,verifiedBuild,maximumPages=10}={}) => {
    const policy=(await db.doc('releasePolicy/android').get()).data()||{};
    if(apply && (!policy.enabled || !Number.isSafeInteger(verifiedBuild) || verifiedBuild<2 ||
        !Number.isSafeInteger(policy.minimumBuild) || policy.minimumBuild<2 || policy.minimumBuild>verifiedBuild ||
        policy.protectedMediaVerifiedBuild!==verifiedBuild || policy.storageCutoverVerified!==true)) {
      throw Error('Verified release, enforced minimum build and verified Storage cutover are required.');
    }
    if(!Number.isSafeInteger(maximumPages)||maximumPages<1||maximumPages>50)throw Error('Invalid page limit');
    const storage=bucket(),ref=db.doc('maintenanceCursors/legacyMediaTokens');
    const saved=apply?(await ref.get()).data():null;
    const prefixes=['users/','community_posts/','chats/'];
    let prefixIndex=saved?.prefixIndex||0,pageToken=saved?.pageToken||undefined;
    if(!Number.isInteger(prefixIndex)||prefixIndex<0||prefixIndex>=prefixes.length)throw Error('Invalid migration cursor');
    let scanned=0,revoked=0,found=0,pages=0;
    const started=now();
    while(prefixIndex<prefixes.length && pages<maximumPages && now()-started<90000){
      const [files,next]=await storage.getFiles({prefix:prefixes[prefixIndex],autoPaginate:false,maxResults:100,...(pageToken?{pageToken}:{})});
      for(const file of files){
        if(!file.name.startsWith(prefixes[prefixIndex]))throw Error('Unexpected object prefix');
        const [meta]=await file.getMetadata();scanned++;
        const tokens=meta.metadata?.firebaseStorageDownloadTokens;
        if(typeof tokens!=='string'||!tokens)continue;
        found++;
        if(apply){
          if(!/^\d+$/.test(String(meta.metageneration||''))||!/^\d+$/.test(String(meta.generation||'')))throw Error('Missing object version');
          // Never erase capabilities on a concurrently replaced generation.
          await file.setMetadata({metadata:{firebaseStorageDownloadTokens:null}},
            {ifGenerationMatch:String(meta.generation),ifMetagenerationMatch:String(meta.metageneration)});
          const [after]=await file.getMetadata();
          if(after.metadata?.firebaseStorageDownloadTokens)throw Error('Token revocation verification failed');
          revoked++;
        }
      }
      pages++;
      pageToken=next?.pageToken||undefined;
      if(!pageToken)prefixIndex++;
      // Failed pages are retried; already-revoked objects make retries harmless.
      if(apply)await ref.set({prefixIndex:prefixIndex===prefixes.length?0:prefixIndex,pageToken:pageToken||null,
        complete:prefixIndex===prefixes.length,verifiedBuild,updatedAt:now()});
    }
    return {apply,scanned,found,revoked,pages,complete:prefixIndex===prefixes.length,nextPrefix:prefixes[prefixIndex]||null};
  };
}
module.exports={createLegacyMediaTokenMigration};