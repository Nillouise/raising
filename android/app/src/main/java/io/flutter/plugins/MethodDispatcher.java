package io.flutter.plugins;


import android.os.Handler;
import android.os.Looper;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.orhanobut.logger.Logger;

import org.apache.commons.lang3.exception.ExceptionUtils;
import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.HashMap;
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

    //一次只会处理一个smb链接
    private Smb smb;

    public Gson gson = new GsonBuilder()
            .setDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ").create();

    @Override
    public void onMethodCall(MethodCall call, @NotNull Result rawResult) {
        Result result = new MethodResultWrapper(rawResult);

        if (call.method.equals("test")) {
            executorService.submit(() -> {
                try {
                    new Smb().test();
                    result.success(null);
                } catch (Exception e) {
                    result.error("test", e.toString(), ExceptionUtils.getStackTrace(e));
                }
            });
            return;
        }

        if (call.method.equals("init")) {
            smb = new Smb(
                    call.argument("hostname"),
                    call.argument("shareName"),
                    call.argument("domain"),
                    call.argument("username"),
                    call.argument("password"),
                    call.argument("path"),
                    call.argument("searchPattern")
            );
            result.success(null);
        } else if (call.method.equals("listFiles")) {
            executorService.submit(() -> {
                try {
                    ArrayList res = smb.listFiles(
                            call.argument("path"),
                            call.argument("searchPattern"),
                            call.argument("share")
                    );
                    result.success(gson.toJson(res));
                } catch (Exception e) {
                    Logger.e(e, "listFiles error");
                    result.error("listFiles", e.toString(), ExceptionUtils.getStackTrace(e));
                }
            });
        } else if (call.method.equals("loadImageFromIndex")) {
            executorService.submit(() -> {
                try {
                    Smb.SmbHalfResult res = smb.processShare(share -> {
                                return smb.loadImageFromIndex(
                                        call.argument("absFilename"),
                                        call.argument("indexs"),
                                        call.argument("needFileDetailInfo"),
                                        share);
                            }, call.argument("share")
                    );
                    result.success(res.getMap());
                } catch (Exception e) {
                    Logger.e(e, "loadImageFromIndex error");
                    //由于发现加入e到errorDetails会导致应用崩溃，所以不加了
                    result.error("loadImageFromIndex", e.toString(), ExceptionUtils.getStackTrace(e));
                }
            });
        } else if (call.method.equals("loadImageFile")) {
            executorService.submit(() -> {
                try {
                    Smb.SmbHalfResult res = smb.processShare(share -> {
                                return smb.loadImageFile(
                                        call.argument("absFilename"),
                                        share);
                            }, call.argument("share")
                    );
                    result.success(res.getMap());
                } catch (Exception e) {
                    Logger.e(e, "loadImageFile error");
                    result.error("loadImageFile", e.toString(), ExceptionUtils.getStackTrace(e));
                }
            });
        } else if (call.method.equals("stopSmbRequest")) {
            executorService.submit(() -> {
                try {
                    smb.stopSmbRequest();
                    result.success(null);
                } catch (Exception e) {
                    Logger.e(e, "stopSmbRequest error");
                    result.error("stopSmbRequest", e.toString(), ExceptionUtils.getStackTrace(e));
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

