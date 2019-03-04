package com.plmlogix.connectyaar;

import android.os.Bundle;

import android.annotation.TargetApi;
import android.content.res.Configuration;
import android.os.Build;
import android.os.Environment;
import android.util.Log;

import com.amazonaws.auth.CognitoCachingCredentialsProvider;
import com.amazonaws.mobileconnectors.s3.transferutility.TransferUtility;
import com.amazonaws.mobileconnectors.s3.transferutility.TransferState;
import com.amazonaws.mobileconnectors.s3.transferutility.TransferObserver;
import com.amazonaws.mobileconnectors.s3.transferutility.TransferListener;
import com.amazonaws.regions.*;
import com.amazonaws.services.s3.*;
import com.amazonaws.services.s3.model.CannedAccessControlList;

import java.io.File;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.Map;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import com.vincent.videocompressor.VideoCompress;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "plmlogix.recordvideo/info";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        //Create OyeYaaro Directory in SD Card, if it's not exists
        File rootDir = new File(Environment.getExternalStorageDirectory().getAbsoluteFile() + "/OyeYaaro"); 
        if (!rootDir.exists() || !rootDir.isDirectory()) {
            rootDir.mkdir();
        }

        //Create Videos Directory in SD Card/OyeYaaro, if it's not exists
        File videoDir = new File(rootDir.getAbsolutePath() + "/sent");//sent
        if (!videoDir.exists() || !videoDir.isDirectory()) {
            videoDir.mkdir();
        }

        //Create .nomedia File in Video Directory, if it's not exists
        File noMediaFile = new File(videoDir.getAbsolutePath() + "/.nomedia");
        if (!noMediaFile.exists() || !noMediaFile.isFile()) {
            try {
                noMediaFile.createNewFile();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        File mediaDir = new File(rootDir.getAbsolutePath() + "/Media");
        if (!mediaDir.exists() || !mediaDir.isDirectory()) {
        mediaDir.mkdir();
        }
        File noMedia = new File(mediaDir.getAbsolutePath() + "/.nomedia");
        if (!noMedia.exists() || !noMedia.isFile()) {
            try {
                noMedia.createNewFile();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(new MethodChannel.MethodCallHandler() {
            @Override
            public void onMethodCall(MethodCall methodCall, final MethodChannel.Result result) {

                final Map<String, Object> arguments = methodCall.arguments();

                if (methodCall.method.equals("compressVideo")) {
                    final String originalVideoUrl = (String) arguments.get("originalVideoUrl");
                    String outDir = Environment.getExternalStorageDirectory().getAbsoluteFile() + "/OyeYaaro" + "/sent";

                    final String destPath = outDir + File.separator + "VID_" + new SimpleDateFormat("yyyyMMdd_HHmmss", getLocale()).format(new Date()) + ".mp4";
                    VideoCompress.compressVideoMedium(originalVideoUrl, destPath, new VideoCompress.CompressListener() {
                        @Override
                        public void onStart() {
                        }

                        @Override
                        public void onSuccess() {
                            result.success(destPath);
                        }

                        @Override
                        public void onFail() {
                            result.error("error", null, null);
                        }

                        @Override
                        public void onProgress(float percent) {
                        }
                    });
                }

                if (methodCall.method.equals("uploadToAmazon")) {
                    String filePath = (String) arguments.get("filePath");
                    String bucket = (String) arguments.get("bucket");
                    String identity = (String) arguments.get("identity");
                    String filename = (String) arguments.get("filename");
                    
                    File fileToUpload = new File(filePath);
          
                    CognitoCachingCredentialsProvider credentialsProvider = new CognitoCachingCredentialsProvider(
                      getApplicationContext(),
                      identity,
                      Regions.US_EAST_1
                  );
                
                    AmazonS3 s3 = new AmazonS3Client(credentialsProvider);
                    s3.setRegion(Region.getRegion(Regions.US_EAST_1));
                    TransferUtility transferUtility = new TransferUtility(s3, getApplicationContext());
          
                    TransferObserver transferObserver = transferUtility.upload(
                      bucket,
                      filename,
                      fileToUpload,
                      CannedAccessControlList.PublicRead
                    );
          
                    transferObserver.setTransferListener(new TransferListener(){
                      
                      @Override
                      public void onStateChanged(int id, TransferState state) {
                          Log.e("statechange", state+"");
                          if (TransferState.COMPLETED == state) {
                            result.success("completed");
                         }
                      }
           
                      @Override
                      public void onProgressChanged(int id, long bytesCurrent, long bytesTotal) {
                          int percentage = (int) (bytesCurrent/bytesTotal * 100);
                          Log.e("percentage",percentage +"");
                      }
           
                      @Override
                      public void onError(int id, Exception ex) {
                          Log.e("error","error");
                          result.error("error", null, null);
                      }
                    });
                }
          
                if (methodCall.method.equals("downloadFromAmazon")) {
                  String bucket = (String) arguments.get("bucket");
                  String identity = (String) arguments.get("identity");
                  final String filename = (String) arguments.get("filename");
          
                  CognitoCachingCredentialsProvider credentialsProvider = new CognitoCachingCredentialsProvider(
                    getApplicationContext(),
                    identity,
                    Regions.US_EAST_1
                );
              
                  AmazonS3 s3 = new AmazonS3Client(credentialsProvider);
                  s3.setRegion(Region.getRegion(Regions.US_EAST_1));
                  TransferUtility transferUtility = new TransferUtility(s3, getApplicationContext());
          
                  File downloadedFile = new File(Environment.getExternalStorageDirectory().getAbsoluteFile() + "/OyeYaaro/Media/" + filename);
                  if (!downloadedFile.exists() || !downloadedFile.isFile()) {
                    try {
                      downloadedFile.createNewFile();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
          
                  TransferObserver transferObserver = transferUtility.download(
                      bucket,
                      filename,
                      downloadedFile
                  );
          
                  transferObserver.setTransferListener(new TransferListener(){
                    
                    @Override
                    public void onStateChanged(int id, TransferState state) {
                        Log.e("statechange", state+"");
                        if (TransferState.COMPLETED == state) {
                          result.success(Environment.getExternalStorageDirectory().getAbsoluteFile() + "/OyeYaaro/Media/" + filename);
                       }
                    }
          
                    @Override
                    public void onProgressChanged(int id, long bytesCurrent, long bytesTotal) {
                      float percentDonef = ((float)bytesCurrent/(float)bytesTotal) * 100;
                        Log.e("percentage",percentDonef +"");  
                    }
          
                    @Override
                    public void onError(int id, Exception ex) {
                        Log.e("error","error");
                        result.error("error", null, null);
                    }
                  });
              }

            }
        });
    }

    private Locale getLocale() {
        Configuration config = getResources().getConfiguration();
        Locale sysLocale = null;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            sysLocale = getSystemLocale(config);
        } else {
            sysLocale = getSystemLocaleLegacy(config);
        }

        return sysLocale;
    }

    @SuppressWarnings("deprecation")
    public static Locale getSystemLocaleLegacy(Configuration config) {
        return config.locale;
    }

    @TargetApi(Build.VERSION_CODES.N)
    public static Locale getSystemLocale(Configuration config) {
        return config.getLocales().get(0);
    }

// //share video
//     public void shareVideo(final String title, String path) {
//         // System.out.println('');
//        MediaScannerConnection.scanFile(this, new String[] { path },

//                    null, new MediaScannerConnection.OnScanCompletedListener() {
//                        public void onScanCompleted(String path, Uri uri) {
//                            Intent shareIntent = new Intent(
//                                    android.content.Intent.ACTION_SEND);
//                            shareIntent.setType("video/*");
//                            shareIntent.putExtra(
//                                    android.content.Intent.EXTRA_SUBJECT, title);
//                            shareIntent.putExtra(
//                                    android.content.Intent.EXTRA_TITLE, title);
//                            shareIntent.putExtra(Intent.EXTRA_STREAM, uri);
//                            shareIntent
//                                    .addFlags(Intent.FLAG_ACTIVITY_CLEAR_WHEN_TASK_RESET);
//                            getApplicationContext().startActivity(Intent.createChooser(shareIntent,
//                                    "Share File"));

//                        }
//                    });
//        }

}