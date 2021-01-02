package com.example.raising;


import android.os.Handler;
import android.os.Looper;

import com.example.raising.vo.DirectoryVO;
import com.example.raising.vo.ExtractCO;
import com.example.raising.vo.SmbCO;
import com.example.raising.vo.SmbResult;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.orhanobut.logger.Logger;

import org.apache.commons.lang3.exception.ExceptionUtils;
import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class MethodDispatcher implements MethodCallHandler {

    // MethodChannel.Result wrapper that responds on the platform thread.
    private static class MethodResultWrapper implements Result {
        private Result methodResult;
        private Handler handler;

        MethodResultWrapper(Result result) {
            methodResult = result;
            handler = new Handler(Looper.getMainLooper());
        }

        @Override
        public void success(final Object result) {
            handler.post(new Runnable() {
                @Override
                public void run() {
                    methodResult.success(result);
                }
            });
        }

        @Override
        public void error(final String errorCode, final String errorMessage, final Object errorDetails) {
            handler.post(new Runnable() {
                @Override
                public void run() {
                    methodResult.error(errorCode, errorMessage, errorDetails);
                }
            });
        }

        @Override
        public void notImplemented() {
            handler.post(new Runnable() {
                @Override
                public void run() {
                    methodResult.notImplemented();
                }
            });
        }
    }


    //    private ConcurrentLinkedQueue<String> previewFileQueue = new ConcurrentLinkedQueue<>();
    private ExecutorService executorService = Executors.newFixedThreadPool(4);

    public Gson gson = new GsonBuilder()
            .setDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ").create();

    @Override
    public void onMethodCall(MethodCall call, @NotNull Result rawResult) {
//        executorService.submit(() -> {
//            try {
//                new WebDavRandomFile("test", 0, 1000).read(new byte[1000]);
//            } catch (Exception e) {
//                Logger.e("new WebDavRandomFile(\\"test\\",0,1000).read(new byte[1000])", e);
//            }
//            Logger.d("onMethodCall continue");
//        });

//        executorService.submit(() -> {
//            try {
//                Logger.i("ExtractChannel.INSTANCE.extract(new WebDavRandomFile(\\"test\\",0,1000)) ");
//                ExtractChannel.INSTANCE.extract(new WebDavRandomFile("test", 0, 149390200), call.argument("indexs"));
//
////                result.success(res.getMap());
//                Logger.i("ExtractChannel successful " + res.getMap().toString());
//            } catch (Exception e) {
//                Logger.e(e, "extract error" + ExceptionUtils.getStackTrace(e));
////                result.error("extract", e.toString(), ExceptionUtils.getStackTrace(e));
//            }
//        });


        Result result = new MethodResultWrapper(rawResult);

        if (call.method.equals("loadWholeFile")) {
            executorService.submit(() -> {
                try {
                    SmbResult res = SmbChannel.INSTANCE.loadWholeFile(SmbCO.fromMap(call.argument("smbCO")));

                    result.success(res.getMap());
                } catch (Exception e) {
                    Logger.e(e, "loadWholeFile error");
                    result.error("loadWholeFile", e.toString(), ExceptionUtils.getStackTrace(e));
                }
            });
        } else if (call.method.equals("loadFileFromZip")) {
            executorService.submit(() -> {
                try {
                    SmbResult res = SmbChannel.INSTANCE.loadFileFromZip(
                            call.argument("indexs"),
                            call.argument("needFileDetailInfo"), SmbCO.fromMap(call.argument("smbCO")));

                    result.success(res.getMap());
                } catch (Exception e) {
                    Logger.e(e, "loadFileFromZip error");
                    //由于发现加入e到errorDetails会导致应用崩溃，所以不加了
                    result.error("loadFileFromZip", e.toString(), ExceptionUtils.getStackTrace(e));
                }
            });
        } else if (call.method.equals("stopSmbRequest")) {
            executorService.submit(() -> {
                try {
                    SmbChannel.INSTANCE.stopSmbRequest();
                    result.success(null);
                } catch (Exception e) {
                    Logger.e(e, "stopSmbRequest error");
                    result.error("stopSmbRequest", e.toString(), ExceptionUtils.getStackTrace(e));
                }
            });
        } else if (call.method.equals("queryFiles")) {
            executorService.submit(() -> {
                try {
                    ArrayList<DirectoryVO> smbCO = SmbChannel.INSTANCE.queryFiles(SmbCO.fromMap(call.argument("smbCO")));
                    result.success(SmbResult.ofSuccessful().setDirectories(smbCO).getMap());
                } catch (Exception e) {
                    Logger.e(e, "queryFiles error");
                    result.error("queryFiles", e.toString(), ExceptionUtils.getStackTrace(e));
                }
            });
        } else if (call.method.equals("webdavExtract")) {
            executorService.submit(() -> {
                try {
                    ExtractCO res = ExtractChannel.INSTANCE.extract(
                            new NativeWebDavRandomFile(call.argument("recallId"), 0, Long.valueOf((int)call.argument("fileSize"))), call.argument("index"));
                    result.success(res.getMap());
                } catch (Exception e) {
                    Logger.e(e, "extract error");
                    result.error("extract", e.toString(), ExceptionUtils.getStackTrace(e));
                }
            });
        } else {
            result.notImplemented();
        }
    }

}

//    private void calculateResult(final String tessDataPath, final String imagePath, final String language,
//                                 final Result result) {
//
//        new AsyncTask<Void, Void, Void>() {
//            @Override
//            protected Void doInBackground(Void... params) {
//
//                result.success(recognizedText[0]);
//                return null;
//            }
//
//            @Override
//            protected void onPostExecute(Void result) {
//                super.onPostExecute(result);
//            }
//        }.execute();
//    }

