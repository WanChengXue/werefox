<script>
    import {onMount} from "svelte";
    export let buttonText1 = "生成一句新的游戏";
    export let buttonText2 = "游戏生成成功之后点击";
    let room_id = "null";
    let show_room_id = false;
    let game_log;
    let step = 0;
    onMount(() => {
        game_log = document.getElementById("game_log");
    });

    async function handleClick1() {
        try {
            const response = await fetch("http://localhost:4000/api/init_game");
            const data = await response.json();
            room_id = data["room_pid"]
            show_room_id = true
            // 在这里添加处理按钮 1 点击的逻辑
        } catch (error) {
        console.error("请求失败:", error);
        }
    }

    async function handleClick2() {
        try {
            const response = await fetch(`http://localhost:4000/api/run_game?room_id=${room_id}`);
            const data = await response.json();
            const stepElement = document.createElement("h4");
            stepElement.textContent = `当前 step 为 ${step}`;
            game_log.appendChild(stepElement);
            for (let key of Object.keys(data)){
                let conversation = data[key]
                let user_index = key.lastIndexOf('_')
                let user  = key.substring(user_index+1)
                let pre_element = document.createElement("pre")
                pre_element.textContent = `${user}: ${conversation}`
                game_log.appendChild(pre_element)
            }
            step += 1

            // 在这里添加处理按钮 1 点击的逻辑
        } catch (error) {
        console.error("请求失败:", error);
        }
    }



    </script>

    <div>
        <button on:click={handleClick1}>{buttonText1}</button>

        {#if show_room_id}
            <p>
                <span>当前的room_id值是 {room_id}</span>
            </p>
        {/if}
        <p>
            <button on:click={handleClick2} disabled={step === 48}>{buttonText2}</button>
        <p/>
        <pre id="game_log"></pre>
    </div>

    <style>
    button {
        margin: 0.5rem;
    }
</style>
