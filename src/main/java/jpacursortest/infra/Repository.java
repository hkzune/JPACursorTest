package jpacursortest.infra;

import jakarta.ejb.Stateless;
import jakarta.ejb.TransactionAttribute;
import jakarta.ejb.TransactionAttributeType;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.TypedQuery;
import jpacursortest.dto.TestDto;
import jpacursortest.entityloader.CacheSafeEntityLoader;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.function.Function;

@Stateless
// 各メソッドでトランザクションを分割するために、TransactionAttributeTypeをREQUIRES_NEWに設定
@TransactionAttribute(TransactionAttributeType.REQUIRES_NEW)
public class Repository {

    @PersistenceContext(unitName = "TEST")
    private EntityManager entityManager;

    private static final String selectQuery = """
            SELECT t
            FROM TestTable t
            """;

    // TestTable内の全てのデータを取得する。
    public List<TestDto> get() {
        TypedQuery<TestTable> typedQuery = this.entityManager.createQuery(selectQuery, TestTable.class);

        List<TestTable> resultList = typedQuery.getResultList();

        return convert(resultList);
    }

    // TestTable内の全てのデータを取得する。
    // 全件取得後、Stream#filterを利用してidListでの絞り込みを行う。
    public List<TestDto> find(List<String> idList) {
        TypedQuery<TestTable> typedQuery = this.entityManager.createQuery(selectQuery, TestTable.class);

        Set<String> idSet = new HashSet<>(idList);

        List<TestTable> reusltList = typedQuery.getResultList()
                .stream()
                .filter(e -> idSet.contains(e.getId()))
                .toList();

        return convert(reusltList);
    }

    // TestTable内の、idListのIDを持つデータを取得する。
    // クエリにIN句を追記して取得する。
    public List<TestDto> findUsingIn(List<String> idList) {
        String in = "WHERE t.id IN :idList";

        String query = selectQuery + in;
        TypedQuery<TestTable> typedQuery = this.entityManager.createQuery(query, TestTable.class)
                .setParameter("idList", idList);

        // SQL Serverはパラメータの数が2100を超えるとエラーになるため、IN句内のパラメータ数を2000ずつに分けてクエリを実行する
        List<TestTable> reusltList = split(idList, 2000, splitIdList -> {
            typedQuery.setParameter("idList", splitIdList);
            return typedQuery.getResultList();
        });

        return convert(reusltList);
    }

    // TestTable内の全てのデータを、CacheSafeEntityLoader#getUsingCursorを利用して取得する。
    // 全件取得後、Stream#filterを利用してidListでの絞り込みを行う。
    public List<TestDto> findUsingCursor(List<String> idList) {
        TypedQuery<TestTable> typedQuery = this.entityManager.createQuery(selectQuery, TestTable.class);

        Set<String> idSet = new HashSet<>(idList);

        List<TestTable> reusltList = CacheSafeEntityLoader.getUsingCursor(this.entityManager, typedQuery)
                .stream()
                .filter(entity -> idSet.contains(entity.getId()))
                .toList();

        return convert(reusltList);
    }

    // sourceListを用いるfunctionを、sourceListの要素をunitSize個ずつに分割して実行する。
    private static <T, E> List<E> split(List<T> sourceList, int unitSize, Function<List<T>, List<E>> function) {
        int index = 0;
        int sourceSize = sourceList.size();

        List<E> result = new ArrayList<>();

        while (index < sourceSize) {
            int nextIndex = Math.min(index + unitSize, sourceSize);
            List<T> subList = sourceList.subList(index, nextIndex);
            result.addAll(function.apply(subList));
            index = nextIndex;
        }

        return result;
    }

    // TestTableをTestDtoに変換する。
    private static List<TestDto> convert(List<TestTable> entityList) {
        return entityList.stream().map(entity ->
                new TestDto(
                        entity.getId(),
                        entity.getName()
                )
        ).toList();
    }
}
