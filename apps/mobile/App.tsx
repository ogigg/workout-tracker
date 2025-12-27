import { StatusBar } from "expo-status-bar";
import { Text, View } from "react-native";
import { Provider as PaperProvider } from "react-native-paper";
import { SafeAreaProvider } from "react-native-safe-area-context";
import "./global.css";

export default function App() {
  return (
    <SafeAreaProvider>
      <PaperProvider>
        <View className="flex-1 items-center justify-center bg-white">
          <Text className="text-xl font-bold mb-4">Workout Tracker Mobile</Text>
          <StatusBar style="auto" />
        </View>
      </PaperProvider>
    </SafeAreaProvider>
  );
}
